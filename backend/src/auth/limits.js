const rateLimit = require('express-rate-limit');
const config = require('../config');

const windowMs = config.security.rateWindowMinutes * 60 * 1000;

function waitMinutes(resetTime) {
  const remainingMs = Math.max(0, resetTime.getTime() - Date.now());
  return Math.max(1, Math.ceil(remainingMs / 60000));
}

function rateLimitResponse(message) {
  return (req, res) => {
    const minutes = waitMinutes(req.rateLimit.resetTime);
    res.set('Retry-After', String(Math.ceil((req.rateLimit.resetTime.getTime() - Date.now()) / 1000)));
    res.status(429).json({ error: `${message} Please wait ${minutes} minute${minutes === 1 ? '' : 's'} before trying again.` });
  };
}

// General protection for every /api route.
const apiLimiter = rateLimit({
  windowMs,
  limit: config.security.apiLimitPerWindow,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  handler: rateLimitResponse('Too many requests.'),
});

// Stricter limit for sign-in to slow down password guessing.
const loginLimiter = rateLimit({
  windowMs,
  limit: config.security.loginLimitPerWindow,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  handler: rateLimitResponse('Too many sign-in attempts.'),
});

module.exports = { apiLimiter, loginLimiter };