// Audit events (Week 13). Best-effort: a failed audit write must never break the workflow.
const logger = require('../logger');

async function recordEvent(pool, issueId, event, actor = 'system') {
  try {
    await pool.query('INSERT INTO issue_events (issue_id, event, actor) VALUES (?, ?, ?)', [issueId, event, actor]);
    return true;
  } catch (err) {
    logger.warn('audit.event.record_failed', { issueId, event, code: err.code || 'UNKNOWN' });
    return false;
  }
}

module.exports = { recordEvent };
