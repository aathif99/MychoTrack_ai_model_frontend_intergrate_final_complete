const db = require('../config/db');

async function ensureSchema() {
    try {
        await db.execute('ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email');
        console.log('[DB Schema] Added profile_picture column to users table');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME' || (e.message && e.message.includes('Duplicate column name'))) {
            // Column already exists, safe to ignore
        } else {
            console.warn('[DB Schema] Notice during users table schema check:', e.message);
        }
    }

    try {
        // Ensure canonical disease mapping is present
        const canonicalDiseases = [
            { id: 0, name: 'Other' },
            { id: 1, name: 'Tinea Corporis' },
            { id: 2, name: 'Tinea Cruris' },
            { id: 3, name: 'Tinea Versicolor' }
        ];

        for (const item of canonicalDiseases) {
            await db.execute(
                'INSERT INTO diseases (disease_id, disease_name) VALUES (?, ?) ON DUPLICATE KEY UPDATE disease_name = VALUES(disease_name)',
                [item.id, item.name]
            );
        }

        // Migrate any historical detections that still reference 'Ringworm'
        await db.execute(
            "UPDATE detections SET disease_class = 'Tinea Corporis' WHERE disease_id = 1 OR disease_class = 'Ringworm'"
        );

        console.log('[DB Schema] Canonical diseases verified (0: Other, 1: Tinea Corporis, 2: Tinea Cruris, 3: Tinea Versicolor)');
    } catch (e) {
        console.warn('[DB Schema] Notice during diseases table schema check:', e.message);
    }
}

module.exports = ensureSchema;
