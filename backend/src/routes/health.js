const express = require('express');
const pool = require('../db');

const router = express.Router();

// GET /api/health  -> is the server up, and can it reach MySQL?
router.get('/', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'up', time: new Date().toISOString() });
  } catch (err) {
    // Safe error: details go to the server console only, never to the client.
    console.error('[health] database check failed:', err.code || err.message);
    res.status(503).json({ status: 'degraded', database: 'down' });
  }
});

module.exports = router;