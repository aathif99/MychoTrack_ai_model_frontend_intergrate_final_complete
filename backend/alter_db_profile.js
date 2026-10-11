const db = require('./config/db');

async function alterTable() {
    try {
        await db.execute('ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email');
        console.log('Successfully added profile_picture column to users table');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME' || (e.message && e.message.includes('Duplicate column name'))) {
            console.log('profile_picture column already exists');
        } else {
            console.error('Error altering users table:', e.message);
        }
    }
    process.exit(0);
}

alterTable();
