const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'ambulance_db',
});

pool.on('error', (err) => {
  console.error('Error inesperado en la piscina de conexiones', err);
});

module.exports = pool;
