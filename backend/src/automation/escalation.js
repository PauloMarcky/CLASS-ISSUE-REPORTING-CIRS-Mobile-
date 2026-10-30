// Aging escalation (Week 13).
// Trigger: schedule (every SCHEDULER_INTERVAL_MINUTES) or manual run by staff.
// Rule: an issue still 'reported' or 'categorized' (nobody assigned it) after
//       ESCALATION_HOURS is flagged is_escalated = 1. Idempotent: already
//       escalated issues are skipped, so running twice does no harm.

const config = require('../config');
const logger = require('../logger');
const { runStep } = require('./retry');
const { recordEvent } = require('./events');

async function escalateStaleIssues(pool, { hours = config.automation.escalationHours, sleepFn } = {}) {
  const found = await runStep(pool, { job: 'escalation_scan', sleepFn }, async () => {
    const [rows] = await pool.query(
      `SELECT id FROM issues
        WHERE status IN ('reported','categorized')
          AND is_escalated = 0
          AND created_at <= (NOW() - INTERVAL ? HOUR)`,
      [hours],
    );
    return rows;
  });

  if (!found.ok) return { ok: false, escalated: 0, needsHuman: true };

  let escalated = 0;
  for (const { id } of found.value) {
    const done = await runStep(pool, { job: 'escalate_issue', issueId: id, sleepFn }, async () => {
      await pool.query('UPDATE issues SET is_escalated = 1, escalated_at = NOW() WHERE id = ? AND is_escalated = 0', [id]);
    });
    if (done.ok) {
      escalated += 1;
      await recordEvent(pool, id, 'escalated', 'system');
      logger.info('automation.issue.escalated', { issueId: id });
    }
  }
  logger.info('automation.escalation.run', { candidates: found.value.length, escalated });
  return { ok: true, candidates: found.value.length, escalated };
}

module.exports = { escalateStaleIssues };
