const mysql = require('./node_modules/mysql2/promise');

async function showDb() {
  try {
    const conn = await mysql.createConnection({
      host: 'skindisease-db-dell.mysql.database.azure.com',
      user: 'Aathif',
      password: 'Aathif225588#',
      database: 'skin_disease_db',
      ssl: { rejectUnauthorized: false }
    });

    console.log('\n================ AZURE MYSQL DATABASE ================');
    const [tables] = await conn.query('SHOW TABLES;');
    console.log('\n--- TABLES ---');
    console.table(tables);

    for (const t of tables) {
      const tableName = Object.values(t)[0];
      const [rows] = await conn.query(`SELECT * FROM \`${tableName}\` LIMIT 10;`);
      console.log(`\n--- TABLE: ${tableName} (Total sampled: ${rows.length}) ---`);
      if (rows.length > 0) {
        console.table(rows);
      } else {
        console.log('(empty)');
      }
    }

    await conn.end();
    console.log('\n======================================================\n');
  } catch (err) {
    console.error('Error connecting to Azure DB:', err.message);
  }
}

showDb();
