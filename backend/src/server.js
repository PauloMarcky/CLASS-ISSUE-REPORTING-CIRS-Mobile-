const app = require('./app');
const config = require('./config');
const pool = require('./db');
const scheduler = require('./automation/scheduler');

app.listen(config.port, '0.0.0.0', () => {
  console.log(`SRMS API running on http://localhost:${config.port}`);
  scheduler.start(pool);
});