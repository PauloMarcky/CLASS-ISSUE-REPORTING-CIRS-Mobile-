const express = require('express');
const crypto = require('crypto');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const logger = require('./logger');
const { apiLimiter } = require('./auth/limits');
const authRoutes = require('./routes/auth');

const healthRoutes = require('./routes/health');
const issueRoutes = require('./routes/issues');
const userRoutes = require('./routes/users');
const automationRoutes = require('./routes/automation');

const app = express();
app.use((req, res, next) => {
  const incoming = req.header('x-correlation-id');
  const correlationId =
    incoming && /^[A-Za-z0-9._-]{1,64}$/.test(incoming)
      ? incoming
      : crypto.randomUUID();
  req.correlationId = correlationId;
  res.setHeader('X-Correlation-ID', correlationId);
  logger.runWithCorrelation(correlationId, next);
});
// Week 14: security headers (helmet) and CORS limited to the configured web origin(s).
app.use(helmet());
app.use(cors({
  origin: (requestOrigin, callback) => {
    if (!requestOrigin) return callback(null, true);
    const isConfigured = config.security.corsOrigins.includes(requestOrigin);
    let isLocalDevelopment = false;
    try {
      const { hostname } = new URL(requestOrigin);
      isLocalDevelopment =
        hostname === 'localhost' || hostname === '127.0.0.1';
    } catch {
      isLocalDevelopment = false;
    }
    return callback(null, isConfigured || isLocalDevelopment);
  },
  methods: ['GET', 'POST', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Correlation-ID'],
}));
app.use('/api', apiLimiter);
app.use(express.json({ limit: '20kb' }));

app.use('/api/auth', authRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/issues', issueRoutes);
app.use('/api/users', userRoutes);
app.use('/api/automation', automationRoutes);

// Unknown route -> consistent JSON error.
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Last-resort error handler: never leak internals.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.type === 'entity.parse.failed' || err.type === 'entity.too.large') {
    return res.status(err.status || 400).json({ error: 'Invalid request body.' });
  }
  console.error('[server] unhandled error:', err.message);
  res.status(500).json({ error: 'Something went wrong on the server.' });
});

module.exports = app;