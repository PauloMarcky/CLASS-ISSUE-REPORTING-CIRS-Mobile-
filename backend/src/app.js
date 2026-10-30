const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const { apiLimiter } = require('./auth/limits');
const authRoutes = require('./routes/auth');

const healthRoutes = require('./routes/health');
const issueRoutes = require('./routes/issues');
const automationRoutes = require('./routes/automation');

const app = express();
// Week 14: security headers (helmet) and CORS limited to the configured web origin(s).
app.use(helmet());
app.use(cors({
  origin: config.security.corsOrigins,
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use('/api', apiLimiter);
app.use(express.json({ limit: '20kb' }));

app.use('/api/auth', authRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/issues', issueRoutes);
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