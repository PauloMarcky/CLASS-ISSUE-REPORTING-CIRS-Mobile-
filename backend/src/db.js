const mysql = require('mysql2/promise');
const config = require('./config');

// One shared connection pool for the whole server.
const pool = mysql.createPool({
  ...config.db,
  waitForConnections: true,
  connectionLimit: 10,
  connectTimeout: 5000,
});

module.exports = pool;