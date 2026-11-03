const express = require('express');
const pool = require('../db');
const logger = require('../logger');
const { routeIssue, teamFor } = require('../automation/routing');
const { findDuplicate } = require('../automation/duplicates');
const { runStep } = require('../automation/retry');
const { recordEvent } = require('../automation/events');

const { requireAuth } = require('../auth/middleware');

const router = express.Router();

const STATUSES = [
  'reported',
  'categorized',
  'assigned',
  'inProgress',
  'resolved',
  'verified',
  'closed',
];

// Database row -> JSON shape that matches the Flutter Issue model.
function toApi(row) {
  return {
    id: String(row.id),
    title: row.title,
    description: row.description,
    location: row.location,
    reporterId: row.reporter_id,
    reporterName: row.reporter_name,
    category: row.category,
    routedTeam: teamFor(row.category),
    priority: row.priority,
    status: row.status,
    assignedToId: row.assigned_to_id,
    assignedToName: row.assigned_to_name,
    isEscalated: Boolean(row.is_escalated),
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

// Returns a list of human-readable problems. Empty list = input is valid.
function validateIssueInput(body) {
  const problems = [];
  const b = body && typeof body === 'object' ? body : {};

  const check = (field, min, max) => {
    const v = b[field];
    if (typeof v !== 'string' || v.trim().length < min) {
      problems.push(`${field} is required (at least ${min} characters).`);
    } else if (v.trim().length > max) {
      problems.push(`${field} must be at most ${max} characters.`);
    }
  };

  check('title', 5, 120);
  check('description', 10, 2000);
  check('location', 3, 120);
  check('reporterId', 1, 10);
  return problems;
}

// POST /api/issues -> report a new issue (workflow trigger).
router.post('/', requireAuth(['student', 'faculty', 'coordinator']), async (req, res) => {
  const input = { ...req.body, reporterId: req.user.id };
  const problems = validateIssueInput(input);
  if (problems.length > 0) {
    logger.warn('issue.create.invalid', { problems });
    return res.status(400).json({ error: 'Invalid issue report.', details: problems });
  }

  const { title, description, location } = req.body;
  const reporterId = req.user.id;
  try {
    const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [reporterId]);
    if (users.length === 0) {
      logger.warn('issue.create.unknown_reporter', { reporterId });
      return res.status(400).json({
        error: 'Invalid issue report.',
        details: ['reporterId does not match a known user.'],
      });
    }

    const route = routeIssue(title, description);

    // The duplicate check is a read, so it is safe to retry. If it still fails,
    // the report is accepted anyway (never lose a report) and the failure is
    // queued for a coordinator.
    const check = await runStep(
      pool,
      { job: 'duplicate_check' },
      () => findDuplicate(pool, { location, category: route.category }),
    );
    const duplicate = check.ok ? check.value : null;
    if (duplicate) {
      logger.info('issue.duplicate.detected', {
        duplicateOfId: duplicate.id,
        reporterId,
        category: route.category,
      });
      return res.status(200).json({
        duplicate: true,
        duplicateOfId: String(duplicate.id),
        message: 'A similar open issue already exists for this location.',
        existingIssue: {
          id: String(duplicate.id),
          title: duplicate.title,
          status: duplicate.status,
        },
      });
    }

    const [result] = await pool.query(
      'INSERT INTO issues (title, description, location, reporter_id, category, priority, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [title.trim(), description.trim(), location.trim(), reporterId, route.category, route.priority, route.status],
    );
    const [rows] = await pool.query('SELECT * FROM issues WHERE id = ?', [result.insertId]);

    await recordEvent(pool, result.insertId, 'created', reporterId);
    if (route.matched) await recordEvent(pool, result.insertId, 'routed', 'system');
    logger.info('issue.created', { issueId: result.insertId, reporterId });
    logger.info(route.matched ? 'issue.routed' : 'issue.routing.needs_human', {
      issueId: result.insertId,
      category: route.category,
      priority: route.priority,
      team: route.team,
      matchedKeyword: route.matchedKeyword,
    });
    return res.status(201).json(toApi(rows[0]));
  } catch (err) {
    logger.error('issue.create.failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

// GET /api/issues?status=reported -> list issues, newest first.
router.get('/', requireAuth(), async (req, res) => {
  const { status } = req.query;
  if (status !== undefined && !STATUSES.includes(status)) {
    return res.status(400).json({ error: 'Invalid status filter.', details: [`status must be one of: ${STATUSES.join(', ')}`] });
  }

  try {
    const baseQuery = `
      SELECT i.*, u1.name as reporter_name, u2.name as assigned_to_name
      FROM issues i
      LEFT JOIN users u1 ON i.reporter_id = u1.id
      LEFT JOIN users u2 ON i.assigned_to_id = u2.id
    `;
    const [rows] = status
      ? await pool.query(`${baseQuery} WHERE i.status = ? ORDER BY i.created_at DESC`, [status])
      : await pool.query(`${baseQuery} ORDER BY i.created_at DESC`);

    const visible = req.user.role === 'coordinator'
      ? rows
      : req.user.role === 'facilitiesStaff'
        ? rows.filter((r) => r.assigned_to_id === req.user.id)
        : rows.filter((r) => r.reporter_id === req.user.id);
    return res.json(visible.map(toApi));
  } catch (err) {
    logger.error('issue.list.failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

// Allowed status transitions (mirrors the Flutter IssueStatus.allowedNext).
const ALLOWED_TRANSITIONS = {
  reported: ['categorized'],
  categorized: ['assigned'],
  assigned: ['inProgress'],
  inProgress: ['resolved'],
  resolved: ['verified', 'inProgress'],
  verified: ['closed'],
  closed: [],
};

// Role-based field permissions.
const FIELD_ROLES = {
  status: ['coordinator', 'facilitiesStaff', 'student', 'faculty'],
  category: ['coordinator'],
  priority: ['coordinator'],
  assignedToId: ['coordinator'],
};

function allowedFieldsForRole(role) {
  return Object.entries(FIELD_ROLES)
    .filter(([, roles]) => roles.includes(role))
    .map(([field]) => field);
}

// PATCH /api/issues/:id -> update issue status, category, priority, or assignment.
router.patch('/:id', requireAuth(['coordinator', 'facilitiesStaff', 'student', 'faculty']), async (req, res) => {
  const issueId = req.params.id;
  if (!issueId || typeof issueId !== 'string' || issueId.trim() === '') {
    return res.status(400).json({ error: 'Invalid issue id.' });
  }

  const { status, category, priority, assignedToId } = req.body;
  const role = req.user.role;
  const allowedFields = allowedFieldsForRole(role);
  const requestedFields = Object.keys(req.body).filter(
    (k) => ['status', 'category', 'priority', 'assignedToId'].includes(k)
  );

  const forbidden = requestedFields.filter((f) => !allowedFields.includes(f));
  if (forbidden.length > 0) {
    logger.warn('issue.update.forbidden_field', { issueId, role, forbidden });
    return res.status(403).json({ error: 'You are not allowed to change those fields.' });
  }

  const updates = [];
  const params = [];

  if (status !== undefined) {
    const validStatuses = ['reported', 'categorized', 'assigned', 'inProgress', 'resolved', 'verified', 'closed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status.', details: ['status must be a valid value.'] });
    }
    updates.push('status = ?');
    params.push(status);
  }

  if (category !== undefined) {
    const validCategories = ['electrical', 'plumbing', 'airConditioning', 'furniture', 'itEquipment', 'cleanliness', 'safety', 'other', null];
    if (!validCategories.includes(category)) {
      return res.status(400).json({ error: 'Invalid category.' });
    }
    updates.push('category = ?');
    params.push(category);
  }

  if (priority !== undefined) {
    const validPriorities = ['low', 'medium', 'high', 'urgent'];
    if (!validPriorities.includes(priority)) {
      return res.status(400).json({ error: 'Invalid priority.' });
    }
    updates.push('priority = ?');
    params.push(priority);
  }

  if (assignedToId !== undefined) {
    if (assignedToId !== null && typeof assignedToId !== 'string') {
      return res.status(400).json({ error: 'Invalid assignedToId.' });
    }
    updates.push('assigned_to_id = ?');
    params.push(assignedToId);
  }

  if (updates.length === 0) {
    return res.status(400).json({ error: 'No valid fields to update.' });
  }

  try {
    const [existing] = await pool.query(
      'SELECT id, status, assigned_to_id, reporter_id FROM issues WHERE id = ?',
      [issueId],
    );
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Issue not found.' });
    }

    if (status !== undefined) {
      const currentStatus = existing[0].status;
      const allowed = ALLOWED_TRANSITIONS[currentStatus] || [];
      if (!allowed.includes(status)) {
        logger.warn('issue.update.invalid_transition', { issueId, from: currentStatus, to: status });
        return res.status(400).json({
          error: 'Invalid status transition.',
          details: [`Cannot move from '${currentStatus}' to '${status}'.`],
        });
      }
    }

    if (assignedToId !== null && assignedToId !== undefined) {
      const [assignees] = await pool.query(
        'SELECT id FROM users WHERE id = ? AND role = ?',
        [assignedToId, 'facilitiesStaff'],
      );
      if (assignees.length === 0) {
        return res.status(400).json({
          error: 'Invalid assignedToId.',
          details: ['Assignee must be a Facilities Staff user.'],
        });
      }
    }

    const currentIssue = existing[0];
    if (role === 'facilitiesStaff' &&
        currentIssue.assigned_to_id !== req.user.id) {
      return res.status(403).json({ error: 'Only the assigned facilitator can update this issue.' });
    }
    if (role === 'student' || role === 'faculty') {
      const [owned] = await pool.query(
        'SELECT id, status, reporter_id FROM issues WHERE id = ? AND reporter_id = ?',
        [issueId, req.user.id],
      );
      if (owned.length === 0) {
        return res.status(403).json({ error: 'You can only verify your own issue.' });
      }
      if (status !== 'verified' || owned[0].status !== 'resolved') {
        return res.status(400).json({
          error: 'Only resolved issues can be verified.',
        });
      }
    }

    params.push(issueId);
    const [result] = await pool.query(
      `UPDATE issues SET ${updates.join(', ')} WHERE id = ?`,
      params
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Issue not found.' });
    }

    const [rows] = await pool.query(`
      SELECT i.*, u1.name as reporter_name, u2.name as assigned_to_name
      FROM issues i
      LEFT JOIN users u1 ON i.reporter_id = u1.id
      LEFT JOIN users u2 ON i.assigned_to_id = u2.id
      WHERE i.id = ?
    `, [issueId]);

    if (status !== undefined) {
      await recordEvent(pool, issueId, 'status_changed', req.user.id);
    }
    logger.info('issue.updated', { issueId, actor: req.user.id, role, fields: requestedFields });
    return res.json(toApi(rows[0]));
  } catch (err) {
    logger.error('issue.update.failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

module.exports = router;
module.exports.validateIssueInput = validateIssueInput;
module.exports.toApi = toApi;