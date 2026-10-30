const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const config = require('../config');
const logger = require('../logger');
const { signToken } = require('../auth/tokens');
const { requireAuth } = require('../auth/middleware');
const { loginLimiter } = require('../auth/limits');
const { validateLoginInput } = require('../auth/validate');

const router = express.Router();

// Unknown emails are compared against this hash so they take about as long as a
// wrong password. This avoids revealing which emails exist through response time.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', config.security.bcryptCost);

async function recordFailure(user) {
  const count = Number(user.failed_logins) + 1;
  if (count >= config.security.maxFailedLogins) {
    await pool.query(
      'UPDATE users SET failed_logins = ?, locked_until = NOW() + INTERVAL ? MINUTE WHERE id = ?',
      [count, config.security.lockoutMinutes, user.id],
    );
    logger.warn('auth.account.locked', { userId: user.id, minutes: config.security.lockoutMinutes });
  } else {
    await pool.query('UPDATE users SET failed_logins = ? WHERE id = ?', [count, user.id]);
  }
}

// POST /api/auth/login -> { token, expiresInSeconds, user }
router.post('/login', loginLimiter, async (req, res) => {
  const problems = validateLoginInput(req.body);
  if (problems.length > 0) {
    return res.status(400).json({ error: 'Invalid sign-in request.', details: problems });
  }

  const email = req.body.email.trim().toLowerCase();
  try {
    const [rows] = await pool.query(
      'SELECT id, name, email, role, password_hash, failed_logins, ' +
        '(locked_until IS NOT NULL AND locked_until > NOW()) AS is_locked ' +
        'FROM users WHERE email = ?',
      [email],
    );
    const user = rows[0];

    if (user && Number(user.is_locked) === 1) {
      logger.warn('auth.login.locked', { userId: user.id });
      return res.status(429).json({ error: 'Too many failed attempts. Please try again later.' });
    }

    const hash = user && user.password_hash ? user.password_hash : DUMMY_HASH;
    const matches = await bcrypt.compare(req.body.password, hash);

    if (!user || !user.password_hash || !matches) {
      if (user) await recordFailure(user);
      logger.warn('auth.login.failed', { userId: user ? user.id : null });
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    await pool.query('UPDATE users SET failed_logins = 0, locked_until = NULL WHERE id = ?', [user.id]);
    const token = signToken(user);
    logger.info('auth.login.success', { userId: user.id, role: user.role });
    return res.json({
      token,
      expiresInSeconds: config.security.tokenMinutes * 60,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (err) {
    logger.error('auth.login.error', { code: err.code || 'UNKNOWN' });
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

// GET /api/auth/me -> who the current token belongs to.
router.get('/me', requireAuth(), (req, res) => {
  res.json({ user: { id: req.user.id, name: req.user.name, role: req.user.role } });
});

module.exports = router;