// ============================================================
// controllers/adminController.js
// Admin-only operations: users, posts, reports management
// ============================================================
const db       = require('../config/database');
const oracledb = require('oracledb');

/** GET /api/admin/users — List all users with stats */
const getAllUsers = async (req, res, next) => {
    try {
        const page   = parseInt(req.query.page)  || 1;
        const limit  = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        const search = req.query.search || '';

        const result = await db.execute(
            `SELECT * FROM (
                SELECT upv.*, ROWNUM AS rn
                FROM user_profile_view upv
                WHERE (:search = '' OR LOWER(upv.username) LIKE LOWER(:like_search)
                                    OR LOWER(upv.fullname) LIKE LOWER(:like_search))
                AND ROWNUM <= :max_row
             ) WHERE rn > :offset`,
            {
                search:      search,
                like_search: `%${search}%`,
                max_row:     offset + limit,
                offset,
            }
        );

        const countResult = await db.execute(
            `SELECT COUNT(*) AS total FROM users
             WHERE (:search = '' OR LOWER(username) LIKE LOWER(:like_search)
                                 OR LOWER(fullname)  LIKE LOWER(:like_search))`,
            { search, like_search: `%${search}%` }
        );

        res.json({
            success: true,
            data: result.rows,
            pagination: {
                page, limit,
                total: countResult.rows[0].TOTAL,
                pages: Math.ceil(countResult.rows[0].TOTAL / limit),
            },
        });

    } catch (err) { next(err); }
};

/** POST /api/admin/users/:id/ban — Ban a user */
const banUser = async (req, res, next) => {
    try {
        const target_id = parseInt(req.params.id);
        const ban       = req.body.ban === true || req.body.ban === 1 ? 1 : 0;

        const result = await db.execute(
            `BEGIN social_media_pkg.ban_user(:admin, :target, :ban, :status); END;`,
            {
                admin:  req.user.user_id,
                target: target_id,
                ban,
                status: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 },
            }
        );

        const status = result.outBinds.status;
        if (status.startsWith('ERROR')) {
            return res.status(400).json({ success: false, message: status });
        }

        res.json({ success: true, message: status });

    } catch (err) { next(err); }
};

/** GET /api/admin/posts — List all posts */
const getAllPosts = async (req, res, next) => {
    try {
        const page   = parseInt(req.query.page)  || 1;
        const limit  = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;

        const result = await db.execute(
            `SELECT * FROM (
                SELECT tv.*, ROWNUM AS rn
                FROM timeline_view tv
                WHERE ROWNUM <= :max_row
             ) WHERE rn > :offset`,
            { max_row: offset + limit, offset }
        );

        res.json({ success: true, data: result.rows });

    } catch (err) { next(err); }
};

/** GET /api/admin/reports — List all reports */
const getAllReports = async (req, res, next) => {
    try {
        const status = req.query.status || 'pending';

        const result = await db.execute(
            `SELECT * FROM admin_reports_view
             WHERE (:status = 'all' OR status = :status)
             FETCH FIRST 50 ROWS ONLY`,
            { status }
        );

        res.json({ success: true, data: result.rows });

    } catch (err) { next(err); }
};

/** PUT /api/admin/reports/:id — Resolve or dismiss a report */
const updateReport = async (req, res, next) => {
    try {
        const { id }     = req.params;
        const { status } = req.body;

        if (!['reviewed', 'resolved', 'dismissed'].includes(status)) {
            return res.status(400).json({ success: false, message: 'Status tidak valid.' });
        }

        await db.execute(
            'UPDATE post_reports SET status = :status WHERE report_id = :id',
            { status, id },
            { autoCommit: true }
        );

        res.json({ success: true, message: `Laporan berhasil ditandai sebagai ${status}.` });

    } catch (err) { next(err); }
};

/** GET /api/admin/stats — Dashboard statistics */
const getDashboardStats = async (req, res, next) => {
    try {
        const stats = await db.execute(
            `SELECT
                (SELECT COUNT(*) FROM users WHERE role = 'user') AS total_users,
                (SELECT COUNT(*) FROM users WHERE is_active = 0) AS banned_users,
                (SELECT COUNT(*) FROM posts)                      AS total_posts,
                (SELECT COUNT(*) FROM comments)                   AS total_comments,
                (SELECT COUNT(*) FROM likes)                      AS total_likes,
                (SELECT COUNT(*) FROM post_reports WHERE status = 'pending') AS pending_reports
             FROM DUAL`
        );

        res.json({ success: true, data: stats.rows[0] });

    } catch (err) { next(err); }
};

module.exports = { getAllUsers, banUser, getAllPosts, getAllReports, updateReport, getDashboardStats };
