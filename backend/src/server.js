const app = require('./app');
const env = require('./config/env');

const server = app.listen(env.port, () => {
  console.log(`Dhopa Bari backend running at http://localhost:${env.port}`);
  console.log(`API health: http://localhost:${env.port}/api/health`);
  if (!env.databaseUrl) {
    console.warn('⚠️  DATABASE_URL is not set — API calls that touch the database will fail. Copy .env.example to .env and configure it.');
  }
});

process.on('unhandledRejection', (err) => {
  console.error('Unhandled rejection:', err);
});

module.exports = server;
