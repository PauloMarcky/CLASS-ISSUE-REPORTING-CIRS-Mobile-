const pool = require('../db');
const logger = require('../logger');
const { verifyToken } = require('./tokens');

// requireAuth()                      -> any signed-in user
// requireAuth(['coordinator', ...])  -> only those roles
// The role is always read from the database, never trusted from the token,
// so a role change or a deleted user takes effect immediately.
function requireAuth(allowedRoles = []) {
  return async function authMiddleware(req, res, next) {
    const header = req.header('authorization') || '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ error: 'Sign in required.' });
    }

    let claims;
    try {
      claims = verifyToken(token);
    } catch (err) {
      if (err.code === 'JWT_SECRET_MISSING') {
        logger.error('auth.config.missing_secret', {});
        return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
      }
      const expired = err.name === 'TokenExpiredError';
      logger.warn('auth.token.rejected', { reason: expired ? 'expired' : 'invalid' });
      return res.status(401).json({
        error: expired ? 'Your session has expired. Please sign in again.' : 'Sign in required.',
      });
    }

    try {
      const [rows] = await pool.query('SELECT id, name, role FROM users WHERE id = ?', [claims.sub]);
      if (rows.length === 0) {
        logger.warn('auth.token.unknown_user', {});
        return res.status(401).json({ error: 'Sign in required.' });
      }
      const user = rows[0];
      if (allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
        logger.warn('auth.access.denied', {
          userId: user.id,
          role: user.role,
          path: req.originalUrl.split('?')[0],
        });
        return res.status(403).json({ error: 'You are not allowed to do this.' });
      }
      req.user = user;
      req.actor = user;
      return next();
    } catch (err) {
      logger.error('auth.lookup.failed', { code: err.code || 'UNKNOWN' });
      return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
    }
  };
}

module.exports = { requireAuth };