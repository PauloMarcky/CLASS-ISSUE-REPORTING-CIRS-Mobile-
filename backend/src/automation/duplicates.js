// Duplicate detection (Week 13).
// Trigger: a new issue has been routed to a category.
// Rule: same location + same category + not closed + created today.

function normalizeLocation(location) {
  return String(location).trim().replace(/\s+/g, ' ').toLowerCase();
}

// Returns the existing open issue row, or null when there is no duplicate.
async function findDuplicate(pool, { location, category }) {
  if (!category) return null; // cannot compare uncategorized reports reliably

  const [rows] = await pool.query(
    `SELECT id, title, status, created_at
       FROM issues
      WHERE category = ?
        AND LOWER(TRIM(location)) = ?
        AND status <> 'closed'
        AND created_at >= CURDATE()
      ORDER BY created_at DESC
      LIMIT 1`,
    [category, normalizeLocation(location), hours],
  );
  return rows.length > 0 ? rows[0] : null;
}

module.exports = { findDuplicate, normalizeLocation };