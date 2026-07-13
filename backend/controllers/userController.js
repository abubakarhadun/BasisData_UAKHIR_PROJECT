// ============================================================
// controllers/userController.js
// User profiles, follow/unfollow, search, edit profile
// ============================================================
const db       = require('../config/database');
const oracledb = require('oracledb');
const bcrypt   = require('bcryptjs');
const path     = require('path');
const fs       = require('fs');

/**
 * GET /api/users/:username
 * Get public profile of a user
 */
const getProfile = async (req, res, next) => {
    try {
        const { username } = req.params;

        const result = await db.execute(
            `SELECT user_id, username, fullname, bio, profile_picture,
                    role, created_at,
                    (SELECT COUNT(*) FROM posts    p WHERE p.user_id = u.user_id) AS total_posts,
                    (SELECT COUNT(*) FROM follows  f WHERE f.following_id = u.user_id) AS total_followers,
                    (SELECT COUNT(*) FROM follows  f WHERE f.follower_id  = u.user_id) AS total_following
             FROM   users u
             WHERE  LOWER(u.username) = LOWER(:uname) AND u.is_active = 1`,
            { uname: username }
        );

        if (!result.rows || result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Pengguna tidak ditemukan.' });
        }

        const profile = result.rows[0];

        // Check if current user is following this profile
        if (req.user) {
            const followCheck = await db.execute(
                'SELECT COUNT(*) AS cnt FROM follows WHERE follower_id = :frid AND following_id = :fgid',
                { frid: req.user.user_id, fgid: profile.USER_ID }
            );
            profile.IS_FOLLOWING = followCheck.rows[0].CNT > 0;
        }

        // Get user's posts
        const postsResult = await db.execute(
            `SELECT post_id, content, image_url, created_at, is_edited,
                    (SELECT COUNT(*) FROM likes    l WHERE l.post_id = p.post_id) AS like_count,
                    (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.post_id) AS comment_count
             FROM   posts p
             WHERE  p.user_id = :userId
             ORDER BY p.created_at DESC
             FETCH FIRST 12 ROWS ONLY`,
            { userId: profile.USER_ID }
        );

        profile.POSTS = postsResult.rows;

        res.json({ success: true, data: profile });

    } catch (err) { next(err); }
};

/**
 * PUT /api/users/profile
 * Update authenticated user's profile
 */
const updateProfile = async (req, res, next) => {
    try {
        const { fullname, bio } = req.body;
        const user_id = req.user.user_id;

        if (!fullname || fullname.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Nama lengkap tidak boleh kosong.' });
        }

        const profile_picture = req.file ? `uploads/${req.file.filename}` : null;

        // If new avatar uploaded, delete the old one
        if (req.file) {
            const oldResult = await db.execute(
                'SELECT profile_picture FROM users WHERE user_id = :id',
                { id: user_id }
            );
            const oldPic = oldResult.rows[0]?.PROFILE_PICTURE;
            if (oldPic && oldPic !== 'uploads/default_avatar.png') {
                const oldPath = path.join(__dirname, '..', oldPic);
                if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
            }
        }

        const sql = profile_picture
            ? `UPDATE users SET fullname = :fn, bio = :bio, profile_picture = :pic WHERE user_id = :id`
            : `UPDATE users SET fullname = :fn, bio = :bio WHERE user_id = :id`;

        const binds = profile_picture
            ? { fn: fullname.trim(), bio: bio || null, pic: profile_picture, id: user_id }
            : { fn: fullname.trim(), bio: bio || null, id: user_id };

        await db.execute(sql, binds, { autoCommit: true });

        res.json({ success: true, message: 'Profil berhasil diperbarui.' });

    } catch (err) { next(err); }
};

/**
 * PUT /api/users/password
 * Change authenticated user's password
 */
const changePassword = async (req, res, next) => {
    try {
        const { current_password, new_password } = req.body;

        if (!current_password || !new_password) {
            return res.status(400).json({ success: false, message: 'Password lama dan baru wajib diisi.' });
        }
        if (new_password.length < 6) {
            return res.status(400).json({ success: false, message: 'Password baru minimal 6 karakter.' });
        }

        const result = await db.execute(
            'SELECT password FROM users WHERE user_id = :id',
            { id: req.user.user_id }
        );

        const match = await bcrypt.compare(current_password, result.rows[0].PASSWORD);
        if (!match) {
            return res.status(401).json({ success: false, message: 'Password lama tidak sesuai.' });
        }

        const hashed = await bcrypt.hash(new_password, 10);
        await db.execute(
            'UPDATE users SET password = :pwd WHERE user_id = :id',
            { pwd: hashed, id: req.user.user_id },
            { autoCommit: true }
        );

        res.json({ success: true, message: 'Password berhasil diubah.' });

    } catch (err) { next(err); }
};

/**
 * POST /api/users/:id/follow
 * Follow or unfollow a user (uses social_media_pkg.follow_user)
 */
const followUser = async (req, res, next) => {
    try {
        const following_id = parseInt(req.params.id);
        const follower_id  = req.user.user_id;

        if (follower_id === following_id) {
            return res.status(400).json({ success: false, message: 'Tidak dapat mengikuti diri sendiri.' });
        }

        const result = await db.execute(
            `BEGIN social_media_pkg.follow_user(:frid, :fgid, :action); END;`,
            {
                frid:   follower_id,
                fgid:   following_id,
                action: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 100 },
            },
            { autoCommit: true }
        );

        const action = result.outBinds.action;

        if (action.startsWith('ERROR')) {
            return res.status(400).json({ success: false, message: action });
        }

        res.json({ success: true, action, message: action === 'FOLLOWED' ? 'Berhasil mengikuti.' : 'Berhenti mengikuti.' });

    } catch (err) { next(err); }
};

/**
 * GET /api/users/:id/followers
 * Get list of followers for a user
 */
const getFollowers = async (req, res, next) => {
    try {
        const result = await db.execute(
            `SELECT u.user_id, u.username, u.fullname, u.profile_picture
             FROM   follows f JOIN users u ON f.follower_id = u.user_id
             WHERE  f.following_id = :id AND u.is_active = 1
             ORDER BY f.created_at DESC`,
            { id: req.params.id }
        );
        res.json({ success: true, data: result.rows });
    } catch (err) { next(err); }
};

/**
 * GET /api/users/:id/following
 * Get list of users that a user is following
 */
const getFollowing = async (req, res, next) => {
    try {
        const result = await db.execute(
            `SELECT u.user_id, u.username, u.fullname, u.profile_picture
             FROM   follows f JOIN users u ON f.following_id = u.user_id
             WHERE  f.follower_id = :id AND u.is_active = 1
             ORDER BY f.created_at DESC`,
            { id: req.params.id }
        );
        res.json({ success: true, data: result.rows });
    } catch (err) { next(err); }
};

/**
 * GET /api/users/search
 * Search users by username or fullname
 */
const searchUsers = async (req, res, next) => {
    try {
        const { q } = req.query;

        if (!q || q.trim().length < 2) {
            return res.status(400).json({ success: false, message: 'Keyword pencarian minimal 2 karakter.' });
        }

        const result = await db.execute(
            `SELECT user_id, username, fullname, profile_picture,
                    (SELECT COUNT(*) FROM follows f WHERE f.following_id = u.user_id) AS follower_count
             FROM   users u
             WHERE  is_active = 1 AND (
                        LOWER(username) LIKE LOWER(:q)
                     OR LOWER(fullname) LIKE LOWER(:q)
                    )
             FETCH FIRST 20 ROWS ONLY`,
            { q: `%${q.trim()}%` }
        );

        res.json({ success: true, data: result.rows });

    } catch (err) { next(err); }
};

module.exports = { getProfile, updateProfile, changePassword, followUser, getFollowers, getFollowing, searchUsers };
