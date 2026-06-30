// ============================================================
// config/database.js
// Oracle Database connection pool configuration
// ============================================================
const oracledb = require('oracledb');

// Use Thin mode (no Oracle Client needed for development)
oracledb.initOracleClient(); // Comment this out to use Thin mode

let pool;

const initPool = async () => {
    try {
        pool = await oracledb.createPool({
            user:             process.env.DB_USER,
            password:         process.env.DB_PASSWORD,
            connectString:    process.env.DB_CONNECT_STRING,
            poolMin:          2,
            poolMax:          10,
            poolIncrement:    1,
            poolTimeout:      60,
            poolAlias:        'default',
        });

        console.log('✅ Oracle Database connection pool created');
        return pool;

    } catch (err) {
        console.error('❌ Failed to create Oracle connection pool:', err.message);
        process.exit(1);
    }
};

/**
 * Execute a SQL query using the connection pool.
 * @param {string} sql   - SQL statement with bind variable placeholders (:name)
 * @param {object} binds - Bind variables object
 * @param {object} opts  - Optional oracledb options (autoCommit, outFormat, etc.)
 */
const execute = async (sql, binds = {}, opts = {}) => {
    let connection;
    try {
        connection = await oracledb.getConnection('default');
        const options = {
            outFormat:  oracledb.OUT_FORMAT_OBJECT, // Return rows as JS objects
            autoCommit: false,                      // Manual commit control
            ...opts,
        };
        const result = await connection.execute(sql, binds, options);
        return result;

    } catch (err) {
        throw err;
    } finally {
        if (connection) {
            try { await connection.close(); }
            catch (closeErr) { console.error('Error closing connection:', closeErr); }
        }
    }
};

/**
 * Execute multiple statements in a single transaction.
 * Automatically commits on success, rolls back on error.
 * @param {Function} transactionFn - Async function receiving a connection
 */
const executeTransaction = async (transactionFn) => {
    let connection;
    try {
        connection = await oracledb.getConnection('default');
        const result = await transactionFn(connection);
        await connection.commit();
        return result;

    } catch (err) {
        if (connection) {
            try { await connection.rollback(); }
            catch (rbErr) { console.error('Rollback error:', rbErr); }
        }
        throw err;

    } finally {
        if (connection) {
            try { await connection.close(); }
            catch (closeErr) { console.error('Error closing connection:', closeErr); }
        }
    }
};

/**
 * Call an Oracle stored procedure.
 * @param {string} procName  - Procedure name (or pkg.proc)
 * @param {object} binds     - Bind variables including OUT params
 */
const callProcedure = async (procName, binds = {}) => {
    // Build the parameter placeholders for the CALL statement
    const params = Object.keys(binds).map(k => `:${k}`).join(', ');
    const sql = `BEGIN ${procName}(${params}); END;`;
    return execute(sql, binds);
};

const closePool = async () => {
    try {
        await oracledb.getPool('default').close(10);
        console.log('Oracle connection pool closed');
    } catch (err) {
        console.error('Error closing pool:', err);
    }
};

module.exports = { initPool, execute, executeTransaction, callProcedure, closePool };
