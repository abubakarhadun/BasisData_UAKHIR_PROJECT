// ============================================================
// app.js
// Express application setup and middleware configuration
// ============================================================
require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const path    = require('path');

const authRoutes  = require('./routes/authRoutes');
const postRoutes  = require('./routes/postRoutes');
const userRoutes  = require('./routes/userRoutes');
const { notifRouter, reportRouter, adminRouter } = require('./routes/userRoutes');

const { errorHandler, notFound } = require('./middleware/errorHandler');

const app = express();

// ---- CORS ----
app.use(cors({
    origin:      process.env.FRONTEND_URL || '*',
    credentials: true,
}));

// ---- Body parsers ----
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ---- Static files (uploaded images) ----
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ---- Health check ----
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString(), env: process.env.NODE_ENV });
});

// ---- API Routes ----
app.use('/api/auth',          authRoutes);
app.use('/api/posts',         postRoutes);
app.use('/api/users',         userRoutes);
app.use('/api/notifications', notifRouter);
app.use('/api/reports',       reportRouter);
app.use('/api/admin',         adminRouter);

// ---- 404 & Error Handlers ----
app.use(notFound);
app.use(errorHandler);

module.exports = app;
