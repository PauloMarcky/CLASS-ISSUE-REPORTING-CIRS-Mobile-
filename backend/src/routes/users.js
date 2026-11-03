const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../auth/middleware');

const router = express.Router();

router.get('/', requireAuth(['coordinator']), async (req, res) => {
  const { role } = req.query;
  if (role !== 'facilitiesStaff') {
    return res.status(400).json({ error: 'Only facilitiesStaff users can be listed.' });
  }

  try {
    const [rows] = await pool.query(
      'SELECT id, name, email, role FROM users WHERE role = ? ORDER BY name',
      [role],
    );
    return res.json(rows);
  } catch (err) {
    return res.status(503).json({ error: 'Service temporarily unavailable. Please try again.' });
  }
});

module.exports = router;
