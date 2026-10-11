const db = require('./config/db');

async function renameRingwormInDb() {
    try {
        console.log('Connecting to database...');
        
        // 1. Update diseases table
        const [diseaseUpdate] = await db.execute(
            "UPDATE diseases SET disease_name = 'Tinea Corporis' WHERE disease_id = 1"
        );
        console.log(`[diseases] Updated ${diseaseUpdate.affectedRows} row(s).`);

        // 2. Update detections table (both where disease_id = 1 or disease_class = 'Ringworm')
        const [detectionsUpdate] = await db.execute(
            "UPDATE detections SET disease_class = 'Tinea Corporis' WHERE disease_id = 1 OR disease_class = 'Ringworm'"
        );
        console.log(`[detections] Updated ${detectionsUpdate.affectedRows} row(s).`);

        // 3. Verify diseases table
        const [diseases] = await db.query('SELECT * FROM diseases ORDER BY disease_id ASC');
        console.log('Current diseases in DB:', diseases);

        // 4. Verify detections table count
        const [countResult] = await db.query(
            "SELECT COUNT(*) AS total FROM detections WHERE disease_class = 'Tinea Corporis'"
        );
        console.log(`Total detections with 'Tinea Corporis': ${countResult[0].total}`);

        const [remainingRingworm] = await db.query(
            "SELECT COUNT(*) AS total FROM detections WHERE disease_class = 'Ringworm'"
        );
        console.log(`Remaining detections with 'Ringworm': ${remainingRingworm[0].total}`);

        console.log('Database update completed successfully.');
        process.exit(0);
    } catch (err) {
        console.error('Error renaming Ringworm in database:', err);
        process.exit(1);
    }
}

renameRingwormInDb();
