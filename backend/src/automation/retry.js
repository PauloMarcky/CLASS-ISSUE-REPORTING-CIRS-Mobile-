// Retry and recovery policy (Week 13).
//
// Policy:
//   - Transient errors (connection reset, timeout, deadlock) are retried with
//     exponential backoff: delay = baseDelayMs * 2^(attempt-1).
//   - Permanent errors are NOT retried.
//   - After a permanent error, or when retries run out, the failure is written
//     to the automation_failures table so a human can act on it.
//   - Only the error CODE is stored/logged, never the error message.
//   - Only wrap operations that are safe to repeat (reads, idempotent writes).

const config = require('../config');
const logger = require('../logger');

const TRANSIENT_CODES = new Set([
  'ECONNRESET',
  'ETIMEDOUT',
  'ECONNREFUSED',
  'EPIPE',
  'PROTOCOL_CONNECTION_LOST',
  'ER_LOCK_DEADLOCK',
  'ER_LOCK_WAIT_TIMEOUT',
  'ER_CON_COUNT_ERROR',
]);

function isTransient(err) {
  return Boolean(err) && TRANSIENT_CODES.has(err.code);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Runs fn(attempt). Returns { ok:true, value, attempts } or
// { ok:false, error, attempts, transient }.
async function withRetry(fn, opts = {}) {
  const {
    job = 'unknown',
    issueId = null,
    maxAttempts = config.automation.retryMaxAttempts,
    baseDelayMs = config.automation.retryBaseDelayMs,
    sleepFn = sleep,
  } = opts;

  for (let attempt = 1; ; attempt += 1) {
    try {
      const value = await fn(attempt);
      if (attempt > 1) {
        logger.info('automation.retry.recovered', { job, issueId, attempts: attempt });
      }
      return { ok: true, value, attempts: attempt };
    } catch (err) {
      const transient = isTransient(err);
      if (transient && attempt < maxAttempts) {
        const delayMs = baseDelayMs * 2 ** (attempt - 1);
        logger.warn('automation.retry.scheduled', {
          job,
          issueId,
          attempt,
          code: err.code,
          delayMs,
        });
        await sleepFn(delayMs);
        continue;
      }
      return { ok: false, error: err, attempts: attempt, transient };
    }
  }
}

// Puts a failed step in the human work queue. Never throws.
async function recordFailure(pool, { job, issueId, errorCode, reason, attempts }) {
  try {
    await pool.query(
      'INSERT INTO automation_failures (job, issue_id, error_code, reason, attempts) VALUES (?, ?, ?, ?, ?)',
      [job, issueId, errorCode, reason, attempts],
    );
    return true;
  } catch (err) {
    // The queue itself is unavailable: the structured log is the last record.
    logger.error('automation.failure.record_failed', { job, issueId, code: err.code || 'UNKNOWN' });
    return false;
  }
}

// withRetry + routing of unrecoverable failures to a human.
// Returns { ok:true, value, attempts } or
// { ok:false, needsHuman:true, reason, errorCode, attempts, queued }.
async function runStep(pool, opts, fn) {
  const result = await withRetry(fn, opts);
  if (result.ok) return result;

  const job = (opts && opts.job) || 'unknown';
  const issueId = (opts && opts.issueId) || null;
  const errorCode = (result.error && result.error.code) || 'UNKNOWN';
  const reason = result.transient ? 'retries_exhausted' : 'permanent';

  const queued = await recordFailure(pool, {
    job,
    issueId,
    errorCode,
    reason,
    attempts: result.attempts,
  });
  logger.error('automation.failed.needs_human', {
    job,
    issueId,
    errorCode,
    reason,
    attempts: result.attempts,
    queued,
  });
  return { ok: false, needsHuman: true, reason, errorCode, attempts: result.attempts, queued };
}

module.exports = { isTransient, withRetry, recordFailure, runStep };