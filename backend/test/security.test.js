const test = require('node:test');
const assert = require('node:assert');

// Must be set before the modules below load the configuration.
const SECRET = 'test-secret-test-secret-test-secret-123456';
process.env.JWT_SECRET = SECRET;

const jwt = require('jsonwebtoken');
const { signToken, verifyToken } = require('../src/auth/tokens');
const { validateLoginInput } = require('../src/auth/validate');

const b64 = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
const nowSeconds = () => Math.floor(Date.now() / 1000);

test('SEC-01 a valid token is accepted and carries the id and role', () => {
  const token = signToken({ id: 'u1', role: 'student' });
  const claims = verifyToken(token);
  assert.strictEqual(claims.sub, 'u1');
  assert.strictEqual(claims.role, 'student');
});

test('SEC-02 a token with an altered role is rejected (tampering)', () => {
  const [h, p, s] = signToken({ id: 'u1', role: 'student' }).split('.');
  const payload = JSON.parse(Buffer.from(p, 'base64url').toString());
  payload.role = 'coordinator';
  const forged = [h, b64(payload), s].join('.');
  assert.throws(() => verifyToken(forged), /invalid signature/);
});

test('SEC-03 an expired token is rejected', () => {
  const expired = jwt.sign(
    { role: 'student', exp: nowSeconds() - 10 },
    SECRET,
    { algorithm: 'HS256', subject: 'u1', issuer: 'srms-api', audience: 'srms-web' },
  );
  assert.throws(() => verifyToken(expired), (err) => err.name === 'TokenExpiredError');
});

test('SEC-04 an unsigned token (alg none) is rejected', () => {
  const header = b64({ alg: 'none', typ: 'JWT' });
  const body = b64({
    sub: 'u4',
    role: 'coordinator',
    iss: 'srms-api',
    aud: 'srms-web',
    exp: nowSeconds() + 600,
  });
  assert.throws(() => verifyToken(`${header}.${body}.`));
});

test('SEC-05 a token signed with a different secret is rejected', () => {
  const other = jwt.sign({ role: 'coordinator' }, 'a-completely-different-secret-value-999', {
    algorithm: 'HS256',
    subject: 'u4',
    issuer: 'srms-api',
    audience: 'srms-web',
    expiresIn: 600,
  });
  assert.throws(() => verifyToken(other), /invalid signature/);
});

test('SEC-06 a token for another audience is rejected', () => {
  const wrong = jwt.sign({ role: 'student' }, SECRET, {
    algorithm: 'HS256',
    subject: 'u1',
    issuer: 'srms-api',
    audience: 'some-other-app',
    expiresIn: 600,
  });
  assert.throws(() => verifyToken(wrong));
});

test('SEC-07 garbage input is rejected', () => {
  assert.throws(() => verifyToken('not-a-token'));
  assert.throws(() => verifyToken(''));
});

test('SEC-08 sign-in input validation', () => {
  assert.deepStrictEqual(validateLoginInput({ email: 'student@srms.test', password: 'x' }), []);
  assert.ok(validateLoginInput({}).length === 2);
  assert.ok(validateLoginInput(null).length === 2);
  assert.ok(validateLoginInput({ email: 123, password: 'x' }).length === 1);
  assert.ok(validateLoginInput({ email: 'a@b.c', password: 'x'.repeat(73) }).length === 1);
  assert.ok(validateLoginInput({ email: 'a'.repeat(151), password: 'x' }).length === 1);
});