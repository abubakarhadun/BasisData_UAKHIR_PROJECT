// ============================================================
// server.js
// Application entry point — starts HTTP server and DB pool
// ============================================================
require('dotenv').config();

const app    = require('./app');
const { initPool, closePool } = require('./config/database');

const PORT = process.env.PORT || 5000;

const start = async () => {
    try {
        // Initialize Oracle connection pool before starting the server
        await initPool();

        const server = app.listen(PORT, () => {
            console.log('');
            console.log('╔══════════════════════════════════════════╗');
            console.log('║   🚀 SOCIAVERSE Backend Server           ║');
            console.log(`║   Port    : ${PORT}                          ║`);
            console.log(`║   Env     : ${process.env.NODE_ENV || 'development'}                 ║`);
            console.log('║   Status  : Running ✅                   ║');
            console.log('╚══════════════════════════════════════════╝');
            console.log('');
        });

        // Graceful shutdown
        const shutdown = async (signal) => {
            console.log(`\n${signal} received. Shutting down gracefully...`);
            server.close(async () => {
                await closePool();
                console.log('Server and DB pool closed. Goodbye!');
                process.exit(0);
            });
        };

        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT',  () => shutdown('SIGINT'));

    } catch (err) {
        console.error('Failed to start server:', err);
        process.exit(1);
    }
};

start();
