// Structured logger (Week 13).
// One JSON object per line -> easy to read, grep, and keep as evidence.
// Sensitive fields are redacted so logs are safe to share in a report.

const REDACTED_KEYS = new Set([
  'password',
  'token',
  'authorization',
  'secret',
  'apikey',
  'description', // free-text from users may contain personal details
  'email',
]);

function redact(value, depth = 0) {
  if (value === null || typeof value !== 'object' || depth > 4) return value;
  if (Array.isArray(value)) return value.map((v) => redact(v, depth + 1));

  const out = {};
  for (const [key, val] of Object.entries(value)) {
    out[key] = REDACTED_KEYS.has(key.toLowerCase())
      ? '[REDACTED]'
      : redact(val, depth + 1);
  }
  return out;
}

function write(level, event, fields = {}) {
  const line = JSON.stringify({
    time: new Date().toISOString(),
    level,
    event,
    ...redact(fields),
  });
  if (level === 'error' || level === 'warn') {
    console.error(line);
  } else {
    console.log(line);
  }
}

module.exports = {
  info: (event, fields) => write('info', event, fields),
  warn: (event, fields) => write('warn', event, fields),
  error: (event, fields) => write('error', event, fields),
  redact,
};