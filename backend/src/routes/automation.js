const express = require('express');
const pool = require('../db');
const logger = require('../logger');
const scheduler = require('../automation/scheduler');
const { requireAuth } = require('../auth/middleware');

const router = express.Router();

// SUPERSEDED in Week 14 by requireAuth (signed tokens); the function below is unused and
// trusted a forgeable x-user-id header. Kept only until the cleanup step. Old note: the role is
// read from the database. A header can be forged; Week 14 replaces this with
// real authentication (signed tokens).
async function requireStaff(req, res, next) {
  const userId = req.header('x-user-id');
  if (!userId) return res.status(401).json({ error: 'Sign in required.' });
  try {
    const [rows] = await pool.query('SELECT id, role FROM users WHERE id = ?', [userId]);
    if (rows.length === 0) return res.status(401).json({ error: 'Sign in required.' });
    if (!['coordinator', 'facilitiesStaff'].includes(rows[0].role)) {
      logger.warn('automation.access.denied', { userId, role: rows[0].role });
      return res.status(403).json({ error: 'You are not allowed to do this.' });
    }
    req.actor = rows[0];
    return next();
  } catch (err) {
    logger.error('automation.auth.failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
}

router.use(requireAuth(['coordinator', 'facilitiesStaff']));

function toApi(row) {
  return {
    id: String(row.id),
    job: row.job,
    issueId: row.issue_id === null ? null : String(row.issue_id),
    errorCode: row.error_code,
    reason: row.reason,
    attempts: row.attempts,
    status: row.status,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

// GET /api/automation/failures?status=open -> the human work queue.
router.get('/failures', async (req, res) => {
  const status = req.query.status || 'open';
  if (!['open', 'resolved'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status filter.', details: ['status must be open or resolved'] });
  }
  try {
    const [rows] = await pool.query('SELECT * FROM automation_failures WHERE status = ? ORDER BY created_at DESC LIMIT 100', [status]);
    return res.json(rows.map(toApi));
  } catch (err) {
    logger.error('automation.failures.list_failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

// POST /api/automation/failures/:id/resolve -> a human marks it handled.
router.post('/failures/:id/resolve', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) return res.status(400).json({ error: 'Invalid failure id.' });
  try {
    const [result] = await pool.query(
      "UPDATE automation_failures SET status = 'resolved', resolved_at = NOW(), resolved_by = ? WHERE id = ? AND status = 'open'",
      [req.actor.id, id],
    );
    if (result.affectedRows === 0) return res.status(404).json({ error: 'No open failure with that id.' });
    logger.info('automation.failure.resolved', { failureId: id, actor: req.actor.id });
    return res.json({ id: String(id), status: 'resolved' });
  } catch (err) {
    logger.error('automation.failure.resolve_failed', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

// POST /api/automation/escalation/run -> run the scheduled job now (demo / manual recovery).
router.post('/escalation/run', async (req, res) => {
  const result = await scheduler.runOnce(pool, 'manual');
  if (result.skipped) return res.status(409).json({ error: 'The job is already running.' });
  logger.info('automation.escalation.manual', { actor: req.actor.id });
  return res.json({ ok: Boolean(result.ok), candidates: result.candidates || 0, escalated: result.escalated || 0, needsHuman: Boolean(result.needsHuman) });
});

// GET /api/automation/status -> last scheduler run.
router.get('/status', (req, res) => {
  res.json({ running: scheduler.state.running, lastRunAt: scheduler.state.lastRunAt, lastResult: scheduler.state.lastResult });
});

module.exports = router;
