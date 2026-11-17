const fs = require('node:fs');
const path = require('node:path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const baseUrl = process.env.SRMS_TEST_API_URL || 'http://localhost:3000';
const testPassword =
  process.env.SRMS_TEST_PASSWORD || process.env.SEED_DEMO_PASSWORD || '';
const output = path.resolve(__dirname, '../../docs/week15_ia6/evidence/api-evidence.json');

async function call(name, method, urlPath, options = {}) {
  const started = new Date();
  const response = await fetch(`${baseUrl}${urlPath}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  const text = await response.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch { json = null; }
  const safeBody = json && typeof json === 'object'
    ? { ...json, ...(Object.prototype.hasOwnProperty.call(json, 'token') ? { token: '[REDACTED]' } : {}) }
    : json;
  return {
    name,
    method,
    path: urlPath,
    startedAt: started.toISOString(),
    completedAt: new Date().toISOString(),
    status: response.status,
    correlationId: response.headers.get('x-correlation-id'),
    headers: Object.fromEntries(response.headers.entries()),
    body: safeBody,
  };
}

async function main() {
  const results = [];
  results.push(await call('health', 'GET', '/api/health'));
  results.push(await call('missing-auth', 'GET', '/api/auth/me'));
  results.push(await call('invalid-login-input', 'POST', '/api/auth/login', { body: {} }));
  results.push(await call('altered-token', 'GET', '/api/auth/me', {
    headers: { Authorization: 'Bearer altered.invalid.token' },
  }));
  results.push(await call('student-forbidden-users', 'GET', '/api/users?role=facilitiesStaff', {
    headers: { Authorization: 'Bearer altered.invalid.token' },
  }));
  results.push(await call('unknown-route', 'GET', '/api/not-a-real-route'));
  if (testPassword) {
    results.push(await call('valid-login', 'POST', '/api/auth/login', {
      body: { email: 'student@srms.test', password: testPassword },
    }));
  } else {
    results.push({
      name: 'valid-login',
      status: 'NOT_RUN',
      reason: 'SRMS_TEST_PASSWORD was not set',
    });
  }
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, JSON.stringify({
    baseUrl,
    recordedAt: new Date().toISOString(),
    secretFreeNote: 'No password or JWT is written to this file.',
    results,
  }, null, 2));
  console.log(output);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
