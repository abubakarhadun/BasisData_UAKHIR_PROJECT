// ============================================================
// controllers/notificationController.js
// Notification management
// ============================================================
const db = require('../config/database');

const getNotifications = async (req, res, next) => {
    try {
        const result = await db.execute(
            `SELECT n.notification_id, n.type, n.reference_id, n.message,
                    n.is_read, n.created_at,
                    s.user_id AS sender_id, s.username AS sender_username,
                    s.profile_picture AS sender_avatar
             FROM   notifications n
             LEFT JOIN users s ON n.sender_id = s.user_id
             WHERE  n.receiver_id = :userId
             ORDER BY n.created_at DESC
             FETCH FIRST 50 ROWS ONLY`,
            { userId: req.user.user_id }
        );
        res.json({ success: true, data: result.rows });
    } catch (err) { next(err); }
};

const markAllRead = async (req, res, next) => {
    try {
        await db.execute(
            'UPDATE notifications SET is_read = 1 WHERE receiver_id = :userId AND is_read = 0',
            { userId: req.user.user_id },
            { autoCommit: true }
        );
        res.json({ success: true, message: 'Semua notifikasi ditandai sudah dibaca.' });
    } catch (err) { next(err); }
};

const markOneRead = async (req, res, next) => {
    try {
        await db.execute(
            'UPDATE notifications SET is_read = 1 WHERE notification_id = :id AND receiver_id = :userId',
            { id: req.params.id, userId: req.user.user_id },
            { autoCommit: true }
        );
        res.json({ success: true, message: 'Notifikasi ditandai sudah dibaca.' });
    } catch (err) { next(err); }
};

module.exports = { getNotifications, markAllRead, markOneRead };


// ============================================================
// controllers/reportController.js
// Post report management
// ============================================================
// (Appended at bottom of this file for simplicity)

const oracledb = require('oracledb');

const submitReport = async (req, res, next) => {
    try {
        const { post_id, reason } = req.body;

        if (!post_id || !reason) {
            return res.status(400).json({ success: false, message: 'post_id dan reason wajib diisi.' });
        }

        const result = await db.execute(
            `BEGIN social_media_pkg.report_post(:rid, :pid, :reason, :rpid, :status); END;`,
            {
                rid:    req.user.user_id,
                pid:    post_id,
                reason,
                rpid:   { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
                status: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 },
            }
        );

        const status = result.outBinds.status;
        if (!status.startsWith('SUCCESS')) {
            return res.status(400).json({ success: false, message: status });
        }

        res.status(201).json({
            success: true,
            message: 'Laporan berhasil dikirim. Tim admin akan meninjaunya.',
            data: { report_id: result.outBinds.rpid },
        });

    } catch (err) { next(err); }
};

module.exports.submitReport = submitReport;
