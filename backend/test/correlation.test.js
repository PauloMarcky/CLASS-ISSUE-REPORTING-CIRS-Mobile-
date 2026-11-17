const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');

test('correlation: response includes a generated correlation id', async () => {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const port = server.address().port;
  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/not-a-real-route`);
    assert.equal(response.status, 404);
    assert.match(response.headers.get('x-correlation-id') || '', /^[0-9a-f-]{36}$/);
  } finally {
    await new Promise((resolve, reject) =>
      server.close((err) => (err ? reject(err) : resolve())),
    );
  }
});

test('correlation: a valid incoming id is preserved', async () => {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const port = server.address().port;
  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/not-a-real-route`, {
      headers: { 'X-Correlation-ID': 'week15-test-001' },
    });
    assert.equal(response.headers.get('x-correlation-id'), 'week15-test-001');
  } finally {
    await new Promise((resolve, reject) =>
      server.close((err) => (err ? reject(err) : resolve())),
    );
  }
});
