// ============================================================
// middleware/auth.js
// JWT authentication and role-based authorization middleware
// ============================================================
const jwt = require('jsonwebtoken');
const db  = require('../config/database');

/**
 * authenticate — Verifies the JWT in the Authorization header.
 * Attaches the decoded user payload to req.user on success.
 */
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'Akses ditolak. Token tidak ditemukan.',
            });
        }

        const token = authHeader.split(' ')[1];

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Verify user still exists and is active
        const result = await db.execute(
            `SELECT user_id, username, email, role, is_active
             FROM   users
             WHERE  user_id = :id`,
            { id: decoded.user_id }
        );

        if (!result.rows || result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Token tidak valid. Pengguna tidak ditemukan.',
            });
        }

        const user = result.rows[0];

        if (user.IS_ACTIVE === 0) {
            return res.status(403).json({
                success: false,
                message: 'Akun Anda telah dinonaktifkan. Hubungi admin.',
            });
        }

        req.user = {
            user_id:  user.USER_ID,
            username: user.USERNAME,
            email:    user.EMAIL,
            role:     user.ROLE,
        };

        next();

    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ success: false, message: 'Sesi telah berakhir. Silakan login kembali.' });
        }
        if (err.name === 'JsonWebTokenError') {
            return res.status(401).json({ success: false, message: 'Token tidak valid.' });
        }
        next(err);
    }
};

/**
 * authorizeAdmin — Middleware that allows only admin role.
 * Must be used AFTER authenticate middleware.
 */
const authorizeAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        return next();
    }
    return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Diperlukan izin administrator.',
    });
};

/**
 * optionalAuth — Attaches user to req if token exists, but does not block
 * requests without a token (for public endpoints that can be enriched).
 */
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = decoded;
        }
    } catch {
        // Silently ignore invalid tokens for optional auth
    }
    next();
};

module.exports = { authenticate, authorizeAdmin, optionalAuth };
