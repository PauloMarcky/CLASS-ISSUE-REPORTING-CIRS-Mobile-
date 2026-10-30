// Scheduler (Week 13). Decision: in-process setInterval, because this is one
// small API instance. Trade-off: if the server is down the job does not run;
// it simply catches up on the next tick because the rule is time-based and idempotent.
// A second instance would need a lock or an external scheduler (see README).

const config = require('../config');
const logger = require('../logger');
const { escalateStaleIssues } = require('./escalation');

const state = { running: false, lastRunAt: null, lastResult: null };

async function runOnce(pool, trigger) {
  if (state.running) {
    logger.warn('automation.scheduler.skipped_overlap', { trigger });
    return { skipped: true };
  }
  state.running = true;
  try {
    const result = await escalateStaleIssues(pool);
    state.lastRunAt = new Date().toISOString();
    state.lastResult = result;
    return result;
  } catch (err) {
    logger.error('automation.scheduler.crashed', { code: err.code || 'UNKNOWN' });
    return { ok: false };
  } finally {
    state.running = false;
  }
}

function start(pool) {
  if (!config.automation.schedulerEnabled) {
    logger.info('automation.scheduler.disabled');
    return null;
  }
  const ms = config.automation.schedulerIntervalMinutes * 60 * 1000;
  logger.info('automation.scheduler.started', { intervalMinutes: config.automation.schedulerIntervalMinutes });
  const timer = setInterval(() => runOnce(pool, 'schedule'), ms);
  timer.unref();
  return timer;
}

module.exports = { start, runOnce, state };
