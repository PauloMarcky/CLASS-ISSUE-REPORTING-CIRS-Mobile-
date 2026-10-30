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

// Database row -> JSON shape that matches the Flutter Issue model.
function toApi(row) {
  return {
    id: String(row.id),
    title: row.title,
    description: row.description,
    location: row.location,
    reporterId: row.reporter_id,
    category: row.category,
    routedTeam: teamFor(row.category),
    priority: row.priority,
    status: row.status,
    assignedToId: row.assigned_to_id,
    isEscalated: Boolean(row.is_escalated),
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
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
    const [rows] = status
      ? await pool.query('SELECT * FROM issues WHERE status = ? ORDER BY created_at DESC', [status])
      : await pool.query('SELECT * FROM issues ORDER BY created_at DESC');
    const canSeeAll = ['coordinator', 'facilitiesStaff'].includes(req.user.role);
    const visible = canSeeAll ? rows : rows.filter((r) => r.reporter_id === req.user.id);
    return res.json(visible.map(toApi));
  } catch (err) {
    logger.error('issue.list.failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

module.exports = router;
module.exports.validateIssueInput = validateIssueInput;
module.exports.toApi = toApi;