const jwt = require('jsonwebtoken');
const config = require('../config');

const ISSUER = 'srms-api';
const AUDIENCE = 'srms-web';
const ALGORITHM = 'HS256';

// The signing secret comes from the environment only. A missing or short secret
// stops token use instead of silently falling back to something guessable.
function secret() {
  const s = config.security.jwtSecret;
  if (!s || s.length < 32) {
    const err = new Error('JWT_SECRET is missing or shorter than 32 characters');
    err.code = 'JWT_SECRET_MISSING';
    throw err;
  }
  return s;
}

// The token carries only the user id (subject) and role. No email, no personal data.
function signToken(user) {
  return jwt.sign({ role: user.role }, secret(), {
    algorithm: ALGORITHM,
    subject: String(user.id),
    issuer: ISSUER,
    audience: AUDIENCE,
    expiresIn: config.security.tokenMinutes * 60,
  });
}

// Only HS256 is accepted, so "alg: none" and algorithm-swap tricks are rejected.
function verifyToken(token) {
  return jwt.verify(token, secret(), {
    algorithms: [ALGORITHM],
    issuer: ISSUER,
    audience: AUDIENCE,
  });
}

module.exports = { signToken, verifyToken };