const db = require('./config/db');

async function alterTable() {
    try {
        await db.execute('ALTER TABLE users DROP INDEX user_name');
        console.log('Removed unique constraint from user_name');
    } catch (e) {
        if (e.code === 'ER_CANT_DROP_FIELD_OR_KEY') console.log('Index user_name does not exist');
        else console.error(e);
    }
    process.exit(0);
}

alterTable();
