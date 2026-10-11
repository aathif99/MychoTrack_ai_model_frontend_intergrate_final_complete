const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function initAzureDatabase(host, user, password) {
    console.log(`Connecting to Azure MySQL: ${host}...`);
    try {
        const connection = await mysql.createConnection({
            host: host,
            port: 3306,
            user: user,
            password: password,
            ssl: { rejectUnauthorized: false },
            multipleStatements: true
        });

        console.log(' Connected to Azure MySQL server successfully!');

        const sqlScript = fs.readFileSync(path.join(__dirname, 'database', 'init.sql'), 'utf8');
        console.log('Executing database/init.sql...');
        await connection.query(sqlScript);
        console.log(' Database and tables created successfully in Azure!');

        const [diseases] = await connection.query('SELECT * FROM skin_disease_db.diseases');
        console.log('Verified diseases in cloud database:', diseases);

        await connection.end();
        console.log('Setup finished cleanly!');
    } catch (err) {
        console.error(' Database initialization error:', err.message);
    }
}

const args = process.argv.slice(2);
const host = args[0] || process.env.AZURE_DB_HOST || 'skindisease-db-dell.mysql.database.azure.com';
const user = args[1] || process.env.AZURE_DB_USER || 'Aathif';
const password = args[2] || process.env.AZURE_DB_PASSWORD || '';

if (!password) {
    console.log('Usage: node init_azure_db.js <host> <user> <password>');
    console.log('Or set AZURE_DB_HOST, AZURE_DB_USER, AZURE_DB_PASSWORD in .env');
} else {
    initAzureDatabase(host, user, password);
}

module.exports = initAzureDatabase;
