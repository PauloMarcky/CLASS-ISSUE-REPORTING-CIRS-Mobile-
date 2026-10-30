// Input validation for the sign-in request. Pure function: no database needed.
// bcrypt only uses the first 72 bytes of a password, so longer input is rejected.
function validateLoginInput(body) {
  const b = body && typeof body === 'object' ? body : {};
  const problems = [];

  if (typeof b.email !== 'string' || b.email.trim().length < 3 || b.email.length > 150) {
    problems.push('email is required (3 to 150 characters).');
  }
  if (typeof b.password !== 'string' || b.password.length < 1 || b.password.length > 72) {
    problems.push('password is required (1 to 72 characters).');
  }
  return problems;
}

module.exports = { validateLoginInput };