const db = require('./config/db');

async function alterTable() {
    try {
        await db.execute('ALTER TABLE users ADD COLUMN email VARCHAR(255) UNIQUE AFTER user_name');
        console.log('Added email column');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') console.log('email column already exists');
        else console.error(e);
    }
    try {
        await db.execute('ALTER TABLE users ADD COLUMN reset_code VARCHAR(6)');
        console.log('Added reset_code column');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') console.log('reset_code column already exists');
        else console.error(e);
    }
    try {
        await db.execute('ALTER TABLE users ADD COLUMN reset_code_expires DATETIME');
        console.log('Added reset_code_expires column');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') console.log('reset_code_expires column already exists');
        else console.error(e);
    }
    process.exit(0);
}

alterTable();
