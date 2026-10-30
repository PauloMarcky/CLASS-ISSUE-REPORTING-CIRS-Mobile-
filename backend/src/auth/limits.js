const rateLimit = require('express-rate-limit');
const config = require('../config');

const windowMs = config.security.rateWindowMinutes * 60 * 1000;

// General protection for every /api route.
const apiLimiter = rateLimit({
  windowMs,
  limit: config.security.apiLimitPerWindow,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Too many requests. Please slow down and try again later.' },
});

// Stricter limit for sign-in to slow down password guessing.
const loginLimiter = rateLimit({
  windowMs,
  limit: config.security.loginLimitPerWindow,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Too many sign-in attempts. Please try again later.' },
});

module.exports = { apiLimiter, loginLimiter };