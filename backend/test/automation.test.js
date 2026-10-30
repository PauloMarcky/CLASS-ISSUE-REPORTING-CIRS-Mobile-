// Run with: npm test   (uses Node's built-in test runner; needs no database)
process.env.DB_PASSWORD = 'x';
const test = require('node:test');
const assert = require('node:assert');

const { routeIssue } = require('../src/automation/routing');
const { runStep } = require('../src/automation/retry');
const { escalateStaleIssues } = require('../src/automation/escalation');
const { redact } = require('../src/logger');

const noWait = async () => {};
const codeError = (code) => Object.assign(new Error('x'), { code });

function fakePool(onQuery) {
  const queries = [];
  return { queries, query: async (sql, params) => { queries.push({ sql, params }); return onQuery ? onQuery(sql, params) : [[]]; } };
}

test('routing: sparking outlet is urgent safety (first rule wins)', () => {
  const r = routeIssue('Sparking outlet', 'The outlet near the door is sparking');
  assert.equal(r.category, 'safety');
  assert.equal(r.priority, 'urgent');
});

test('routing: unknown text is left for a human', () => {
  const r = routeIssue('Strange thing', 'Something odd happened in the room');
  assert.equal(r.matched, false);
  assert.equal(r.status, 'reported');
});

test('retry: transient failure recovers', async () => {
  let calls = 0;
  const r = await runStep(fakePool(), { job: 't', sleepFn: noWait }, async () => { calls += 1; if (calls < 3) throw codeError('ECONNRESET'); return 'ok'; });
  assert.equal(r.ok, true);
  assert.equal(r.attempts, 3);
});

test('retry: permanent failure is not retried and goes to the human queue', async () => {
  const pool = fakePool();
  let calls = 0;
  const r = await runStep(pool, { job: 't', issueId: 5, sleepFn: noWait }, async () => { calls += 1; throw codeError('ER_NO_REFERENCED_ROW_2'); });
  assert.equal(calls, 1);
  assert.equal(r.needsHuman, true);
  assert.equal(r.reason, 'permanent');
  assert.match(pool.queries[0].sql, /automation_failures/);
});

test('retry: exhausted transient failure goes to the human queue', async () => {
  const r = await runStep(fakePool(), { job: 't', sleepFn: noWait }, async () => { throw codeError('ETIMEDOUT'); });
  assert.equal(r.reason, 'retries_exhausted');
  assert.equal(r.attempts, 3);
});

test('escalation: stale issues are flagged and audited', async () => {
  const pool = fakePool((sql) => (sql.startsWith('SELECT') ? [[{ id: 7 }, { id: 8 }]] : [{}]));
  const r = await escalateStaleIssues(pool, { hours: 24, sleepFn: noWait });
  assert.equal(r.escalated, 2);
  assert.equal(pool.queries.filter((q) => q.sql.startsWith('UPDATE issues')).length, 2);
  assert.equal(pool.queries.filter((q) => q.sql.includes('issue_events')).length, 2);
});

test('escalation: database down is retried then queued for a human', async () => {
  const pool = fakePool((sql) => { if (sql.startsWith('SELECT')) throw codeError('ECONNREFUSED'); return [{}]; });
  const r = await escalateStaleIssues(pool, { hours: 24, sleepFn: noWait });
  assert.equal(r.ok, false);
  assert.equal(r.needsHuman, true);
});

test('logger: sensitive fields are redacted', () => {
  const out = redact({ email: 'a@b.c', description: 'private', issueId: 3 });
  assert.equal(out.email, '[REDACTED]');
  assert.equal(out.description, '[REDACTED]');
  assert.equal(out.issueId, 3);
});
