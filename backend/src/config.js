require('dotenv').config();

// All settings come from environment variables (.env file). No secrets in code.
module.exports = {
  port: Number(process.env.PORT) || 3000,
  automation: {
    duplicateWindowHours: Number(process.env.DUPLICATE_WINDOW_HOURS) || 48,
    retryMaxAttempts: Number(process.env.RETRY_MAX_ATTEMPTS) || 3,
    retryBaseDelayMs: Number(process.env.RETRY_BASE_DELAY_MS) || 200,
    escalationHours: Number(process.env.ESCALATION_HOURS) || 24,
    schedulerEnabled: process.env.SCHEDULER_ENABLED !== 'false',
    schedulerIntervalMinutes: Number(process.env.SCHEDULER_INTERVAL_MINUTES) || 15,
  },
  security: {
    jwtSecret: process.env.JWT_SECRET || '',
    tokenMinutes: Number(process.env.TOKEN_MINUTES) || 30,
    bcryptCost: Number(process.env.BCRYPT_COST) || 12,
    maxFailedLogins: Number(process.env.MAX_FAILED_LOGINS) || 5,
    lockoutMinutes: Number(process.env.LOCKOUT_MINUTES) || 15,
    corsOrigins: (process.env.CORS_ORIGINS || 'http://localhost:5000')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
    rateWindowMinutes: Number(process.env.RATE_WINDOW_MINUTES) || 15,
    apiLimitPerWindow: Number(process.env.API_RATE_LIMIT) || 300,
    loginLimitPerWindow: Number(process.env.LOGIN_RATE_LIMIT) || 10,
    tls: {
      keyPath: process.env.TLS_KEY_PATH || '',
      certPath: process.env.TLS_CERT_PATH || '',
      port: Number(process.env.HTTPS_PORT) || 3443,
    },
  },
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'srms_app',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'srms',
  },
};