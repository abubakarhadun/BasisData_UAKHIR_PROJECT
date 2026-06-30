/**
 * Run this with: node gen_hash.js
 * Paste the output into sample_data.sql to replace '$2b$10$YourBcryptHashHere'
 */
const bcrypt = require('bcryptjs');

async function main() {
    const password = 'Password123!';
    const hash = await bcrypt.hash(password, 10);
    console.log('Password:', password);
    console.log('Hash:', hash);
    console.log('');
    console.log('Replace all occurrences of:');
    console.log("  '$2b$10$YourBcryptHashHere'");
    console.log('With:');
    console.log(`  '${hash}'`);
    console.log('');
    console.log('in database/sample_data.sql');
}

main();
