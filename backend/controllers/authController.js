// ============================================================
// controllers/authController.js
// Authentication: Register, Login, Logout, Me
// ============================================================
const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const db     = require('../config/database');
const oracledb = require('oracledb');

/**
 * POST /api/auth/register
 * Register a new user account
 */
const register = async (req, res, next) => {
    try {
        const { username, email, password, fullname } = req.body;

        // Validate required fields
        if (!username || !email || !password || !fullname) {
            return res.status(400).json({
                success: false,
                message: 'Semua field wajib diisi: username, email, password, fullname.',
            });
        }

        // Validate username format (alphanumeric + underscore, 3-30 chars)
        const usernameRegex = /^[a-zA-Z0-9_]{3,30}$/;
        if (!usernameRegex.test(username)) {
            return res.status(400).json({
                success: false,
                message: 'Username hanya boleh huruf, angka, underscore. Panjang 3-30 karakter.',
            });
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ success: false, message: 'Format email tidak valid.' });
        }

        // Validate password strength
        if (password.length < 6) {
            return res.status(400).json({ success: false, message: 'Password minimal 6 karakter.' });
        }

        // Check if username already taken
        const usernameCheck = await db.execute(
            'SELECT COUNT(*) AS cnt FROM users WHERE LOWER(username) = LOWER(:uname)',
            { uname: username }
        );
        if (usernameCheck.rows[0].CNT > 0) {
            return res.status(409).json({ success: false, message: 'Username sudah digunakan.' });
        }

        // Check if email already registered
        const emailCheck = await db.execute(
            'SELECT COUNT(*) AS cnt FROM users WHERE LOWER(email) = LOWER(:email)',
            { email }
        );
        if (emailCheck.rows[0].CNT > 0) {
            return res.status(409).json({ success: false, message: 'Email sudah terdaftar.' });
        }

        // Hash password with bcrypt (salt rounds = 10)
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert new user
        const insertResult = await db.execute(
            `INSERT INTO users (username, email, password, fullname, role, is_active)
             VALUES (:username, :email, :password, :fullname, 'user', 1)
             RETURNING user_id INTO :user_id`,
            {
                username:  username.toLowerCase(),
                email:     email.toLowerCase(),
                password:  hashedPassword,
                fullname,
                user_id:   { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
            },
            { autoCommit: true }
        );

        const newUserId = insertResult.outBinds.user_id[0];

        // Generate JWT token
        const token = jwt.sign(
            { user_id: newUserId, username: username.toLowerCase(), role: 'user' },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        res.status(201).json({
            success: true,
            message: 'Registrasi berhasil!',
            data: {
                token,
                user: {
                    user_id:  newUserId,
                    username: username.toLowerCase(),
                    email:    email.toLowerCase(),
                    fullname,
                    role:     'user',
                },
            },
        });

    } catch (err) {
        next(err);
    }
};

/**
 * POST /api/auth/login
 * Login with username/email and password
 */
const login = async (req, res, next) => {
    try {
        const { login: loginInput, password } = req.body;

        if (!loginInput || !password) {
            return res.status(400).json({
                success: false,
                message: 'Username/email dan password wajib diisi.',
            });
        }

        // Find user by username or email
        const result = await db.execute(
            `SELECT user_id, username, email, password, fullname, 
                    bio, profile_picture, role, is_active
             FROM   users
             WHERE  LOWER(username) = LOWER(:login) 
                OR  LOWER(email)    = LOWER(:login)`,
            { login: loginInput }
        );

        if (!result.rows || result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Username/email atau password tidak valid.',
            });
        }

        const user = result.rows[0];

        // Check if account is active
        if (user.IS_ACTIVE === 0) {
            return res.status(403).json({
                success: false,
                message: 'Akun Anda telah dinonaktifkan. Hubungi admin.',
            });
        }

        // Verify password
        const passwordMatch = await bcrypt.compare(password, user.PASSWORD);
        if (!passwordMatch) {
            return res.status(401).json({
                success: false,
                message: 'Username/email atau password tidak valid.',
            });
        }

        // Update last_login timestamp
        await db.execute(
            'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = :id',
            { id: user.USER_ID },
            { autoCommit: true }
        );

        // Generate JWT token
        const token = jwt.sign(
            { user_id: user.USER_ID, username: user.USERNAME, role: user.ROLE },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        res.json({
            success: true,
            message: 'Login berhasil!',
            data: {
                token,
                user: {
                    user_id:         user.USER_ID,
                    username:        user.USERNAME,
                    email:           user.EMAIL,
                    fullname:        user.FULLNAME,
                    bio:             user.BIO,
                    profile_picture: user.PROFILE_PICTURE,
                    role:            user.ROLE,
                },
            },
        });

    } catch (err) {
        next(err);
    }
};

/**
 * GET /api/auth/me
 * Get current authenticated user info
 */
const getMe = async (req, res, next) => {
    try {
        const result = await db.execute(
            `SELECT u.user_id, u.username, u.email, u.fullname, u.bio,
                    u.profile_picture, u.role, u.created_at, u.last_login,
                    (SELECT COUNT(*) FROM posts    p WHERE p.user_id = u.user_id) AS total_posts,
                    (SELECT COUNT(*) FROM follows  f WHERE f.following_id = u.user_id) AS total_followers,
                    (SELECT COUNT(*) FROM follows  f WHERE f.follower_id  = u.user_id) AS total_following,
                    (SELECT COUNT(*) FROM notifications n WHERE n.receiver_id = u.user_id AND n.is_read = 0) AS unread_count
             FROM   users u
             WHERE  u.user_id = :id`,
            { id: req.user.user_id }
        );

        if (!result.rows || result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Pengguna tidak ditemukan.' });
        }

        const user = result.rows[0];
        res.json({ success: true, data: user });

    } catch (err) {
        next(err);
    }
};

/**
 * POST /api/auth/logout
 * Logout (client-side token removal; server-side is stateless JWT)
 */
const logout = (req, res) => {
    res.json({ success: true, message: 'Logout berhasil.' });
};

module.exports = { register, login, getMe, logout };
