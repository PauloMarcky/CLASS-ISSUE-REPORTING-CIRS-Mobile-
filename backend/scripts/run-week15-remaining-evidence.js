const fs = require('node:fs');
const path = require('node:path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const baseUrl = process.env.SRMS_TEST_API_URL || 'http://127.0.0.1:3000';
const password = process.env.SEED_DEMO_PASSWORD || process.env.SRMS_TEST_PASSWORD || '';
const output = path.resolve(__dirname, '../../docs/week15_ia6/evidence/remaining-live-evidence.json');

async function raw(name, method, urlPath, options = {}) {
  const startedAt = new Date().toISOString();
  const response = await fetch(`${baseUrl}${urlPath}`, {
    method,
    headers: options.headers || {},
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  const text = await response.text();
  let body = null;
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  if (body && typeof body === 'object' && Object.prototype.hasOwnProperty.call(body, 'token')) {
    body.token = '[REDACTED]';
  }
  return {
    name,
    method,
    path: urlPath,
    startedAt,
    completedAt: new Date().toISOString(),
    status: response.status,
    correlationId: response.headers.get('x-correlation-id'),
    allowOrigin: response.headers.get('access-control-allow-origin'),
    body,
  };
}

async function login(email) {
  const response = await fetch(`${baseUrl}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const body = await response.json();
  return { status: response.status, token: body.token, user: body.user };
}

async function main() {
  if (!password) throw new Error('No secret-free local test password configured.');
  const cors = await raw('cors-unknown-origin', 'GET', '/api/health', {
    headers: { Origin: 'https://unknown.invalid' },
  });
  const studentLogin = await login('student@srms.test');
  const facultyLogin = await login('faculty@srms.test');
  const coordinatorLogin = await login('coordinator@srms.test');
  if (!studentLogin.token || !facultyLogin.token || !coordinatorLogin.token) {
    throw new Error(`Login setup failed: student=${studentLogin.status}, faculty=${facultyLogin.status}, coordinator=${coordinatorLogin.status}`);
  }
  const studentHeaders = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${studentLogin.token}`,
  };
  const first = await raw('duplicate-first-submission', 'POST', '/api/issues', {
    headers: studentHeaders,
    body: {
      title: 'Sparking outlet - Week15 controlled duplicate',
      location: 'Test Building - Room 101',
      description: 'Controlled fictional outlet sparking issue used for duplicate evidence.',
    },
  });
  const second = await raw('duplicate-second-submission', 'POST', '/api/issues', {
    headers: studentHeaders,
    body: {
      title: 'Sparking outlet - Week15 controlled duplicate',
      location: 'Test Building - Room 101',
      description: 'Repeated controlled fictional outlet issue for duplicate evidence.',
    },
  });
  let object403 = null;
  let controlledIssueId = null;
  if (second.status === 201) controlledIssueId = second.body.id;
  if (second.status === 200 && second.body && second.body.duplicate) {
    controlledIssueId = second.body.duplicateOfId;
  }
  if (controlledIssueId) {
    const coordinatorHeaders = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${coordinatorLogin.token}`,
    };
    const transitions = [
      ['categorized', 'categorized'],
      ['assigned', 'assigned'],
      ['inProgress', 'inProgress'],
      ['resolved', 'resolved'],
    ];
    for (const [name, status] of transitions) {
      await raw(`object-state-${name}`, 'PATCH', `/api/issues/${controlledIssueId}`, {
        headers: coordinatorHeaders,
        body: { status },
      });
    }
    object403 = await raw('object-level-403-other-user', 'PATCH', `/api/issues/${controlledIssueId}`, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${facultyLogin.token}`,
      },
      body: { status: 'verified' },
    });
  } else {
    object403 = {
      name: 'object-level-403-other-user',
      status: 'NOT_RUN',
      reason: `Could not establish a controlled issue; second submission status=${second.status}`,
    };
  }

  const report = {
    baseUrl,
    recordedAt: new Date().toISOString(),
    secretFreeNote: 'Passwords and bearer tokens are never written.',
    results: [cors, first, second, object403],
  };
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, JSON.stringify(report, null, 2));
  console.log(output);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
