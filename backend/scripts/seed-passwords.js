// Sets bcrypt password hashes for the fictional demo accounts (@srms.test only).
// The password is read from the SEED_DEMO_PASSWORD environment variable.
// It is never stored in the repository and never printed.
//
// Windows (cmd):   set SEED_DEMO_PASSWORD=YourStrongPassHere1 && npm run seed:passwords
const bcrypt = require('bcryptjs');
const pool = require('../src/db');
const config = require('../src/config');

async function main() {
  const password = process.env.SEED_DEMO_PASSWORD || '';
  const strong =
    password.length >= 12 &&
    password.length <= 72 &&
    /[a-z]/.test(password) &&
    /[A-Z]/.test(password) &&
    /[0-9]/.test(password);
  if (!strong) {
    console.error('Set SEED_DEMO_PASSWORD first (12 to 72 characters with upper, lower and a digit). Nothing was changed.');
    process.exit(1);
  }

  const [users] = await pool.query("SELECT id FROM users WHERE email LIKE '%@srms.test'");
  for (const u of users) {
    const hash = await bcrypt.hash(password, config.security.bcryptCost);
    await pool.query(
      'UPDATE users SET password_hash = ?, failed_logins = 0, locked_until = NULL WHERE id = ?',
      [hash, u.id],
    );
  }
  console.log(`Passwords set for ${users.length} demo account(s).`);
  await pool.end();
}

main().catch((err) => {
  console.error('seed failed:', err.code || 'UNKNOWN');
  process.exit(1);
});