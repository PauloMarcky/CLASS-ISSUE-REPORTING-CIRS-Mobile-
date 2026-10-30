// Demo of the retry and recovery policy. Needs NO database (uses a fake one).
// Run:  node backend/scripts/demo-recovery.js
// Keep the output as Week 13 evidence.

const { runStep } = require('../src/automation/retry');

const fakePool = {
  query: async (sql, params) => {
    console.log('  [fake DB] automation_failures row:', JSON.stringify(params));
    return [{ insertId: 1 }];
  },
};
const noWait = async () => {};

function codeError(code) {
  const err = new Error('simulated failure');
  err.code = code;
  return err;
}

(async () => {
  console.log('--- Scenario 1: transient failure, recovered by retry ---');
  let calls = 0;
  const r1 = await runStep(fakePool, { job: 'duplicate_check', issueId: 101, sleepFn: noWait }, async () => {
    calls += 1;
    if (calls < 3) throw codeError('ECONNRESET');
    return 'done';
  });
  console.log('  result:', JSON.stringify({ ok: r1.ok, attempts: r1.attempts }));

  console.log('--- Scenario 2: permanent failure, routed for human action ---');
  const r2 = await runStep(fakePool, { job: 'assign_team', issueId: 102, sleepFn: noWait }, async () => {
    throw codeError('ER_NO_REFERENCED_ROW_2');
  });
  console.log('  result:', JSON.stringify({ ok: r2.ok, needsHuman: r2.needsHuman, reason: r2.reason, attempts: r2.attempts }));

  console.log('--- Scenario 3: transient failure that never recovers ---');
  const r3 = await runStep(fakePool, { job: 'aging_alert', issueId: 103, sleepFn: noWait }, async () => {
    throw codeError('ETIMEDOUT');
  });
  console.log('  result:', JSON.stringify({ ok: r3.ok, needsHuman: r3.needsHuman, reason: r3.reason, attempts: r3.attempts }));
})();