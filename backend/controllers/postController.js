// ============================================================
// controllers/postController.js
// CRUD for Posts, Likes, Comments
// ============================================================
const db       = require('../config/database');
const oracledb = require('oracledb');
const path     = require('path');
const fs       = require('fs');

/**
 * GET /api/posts
 * Fetch timeline posts (paginated). Shows posts from all users.
 */
const getTimeline = async (req, res, next) => {
    try {
        const page  = parseInt(req.query.page)  || 1;
        const limit = parseInt(req.query.limit) || 10;
        const offset = (page - 1) * limit;

        const result = await db.execute(
            `SELECT * FROM (
                SELECT tv.*, ROWNUM AS rn
                FROM   timeline_view tv
                WHERE  ROWNUM <= :max_row
             ) WHERE rn > :offset`,
            { max_row: offset + limit, offset }
        );

        // If user is authenticated, attach their like status to each post
        let likedPostIds = new Set();
        if (req.user) {
            const likedResult = await db.execute(
                `SELECT post_id FROM likes WHERE user_id = :uid`,
                { uid: req.user.user_id }
            );
            likedPostIds = new Set(likedResult.rows.map(r => r.POST_ID));
        }

        const posts = result.rows.map(row => ({
            ...row,
            IS_LIKED_BY_ME: likedPostIds.has(row.POST_ID),
        }));

        // Get total count for pagination
        const countResult = await db.execute(
            `SELECT COUNT(*) AS total FROM posts p
             JOIN users u ON p.user_id = u.user_id WHERE u.is_active = 1`
        );
        const total = countResult.rows[0].TOTAL;

        res.json({
            success: true,
            data: posts,
            pagination: { page, limit, total, pages: Math.ceil(total / limit) },
        });

    } catch (err) { next(err); }
};

/**
 * GET /api/posts/:id
 * Get a single post with comments
 */
const getPost = async (req, res, next) => {
    try {
        const { id } = req.params;

        const postResult = await db.execute(
            `SELECT p.post_id, p.user_id, p.content, p.image_url, p.created_at,
                    p.updated_at, p.is_edited,
                    u.username, u.fullname, u.profile_picture,
                    (SELECT COUNT(*) FROM likes    l WHERE l.post_id = p.post_id) AS like_count,
                    (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.post_id) AS comment_count
             FROM   posts p JOIN users u ON p.user_id = u.user_id
             WHERE  p.post_id = :id AND u.is_active = 1`,
            { id }
        );

        if (!postResult.rows || postResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Postingan tidak ditemukan.' });
        }

        // Get comments for this post
        const commentsResult = await db.execute(
            `SELECT c.comment_id, c.comment_text, c.created_at,
                    u.user_id, u.username, u.profile_picture
             FROM   comments c JOIN users u ON c.user_id = u.user_id
             WHERE  c.post_id = :id
             ORDER BY c.created_at ASC`,
            { id }
        );

        const post = postResult.rows[0];
        post.COMMENTS = commentsResult.rows;

        // Check if authenticated user liked this post
        if (req.user) {
            const likeCheck = await db.execute(
                'SELECT COUNT(*) AS cnt FROM likes WHERE post_id = :pid AND user_id = :uid',
                { pid: id, uid: req.user.user_id }
            );
            post.IS_LIKED_BY_ME = likeCheck.rows[0].CNT > 0;
        }

        res.json({ success: true, data: post });

    } catch (err) { next(err); }
};

/**
 * POST /api/posts
 * Create a new post (uses sp_create_post via stored procedure)
 */
const createPost = async (req, res, next) => {
    try {
        const { content } = req.body;
        const image_url   = req.file ? `uploads/${req.file.filename}` : null;

        if (!content || content.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Konten postingan tidak boleh kosong.' });
        }

        // Call stored procedure via direct SQL (package-compatible)
        const result = await db.execute(
            `BEGIN social_media_pkg.create_post(:uid, :content, :img, :pid, :status); END;`,
            {
                uid:     req.user.user_id,
                content: content.trim(),
                img:     image_url,
                pid:     { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
                status:  { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 },
            }
        );

        const status   = result.outBinds.status;
        const post_id  = result.outBinds.pid;

        if (!status.startsWith('SUCCESS')) {
            return res.status(400).json({ success: false, message: status });
        }

        res.status(201).json({
            success: true,
            message: 'Postingan berhasil dibuat.',
            data: { post_id, content: content.trim(), image_url },
        });

    } catch (err) { next(err); }
};

/**
 * PUT /api/posts/:id
 * Update own post content
 */
const updatePost = async (req, res, next) => {
    try {
        const { id }     = req.params;
        const { content } = req.body;

        if (!content || content.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Konten tidak boleh kosong.' });
        }

        // Verify ownership
        const ownerCheck = await db.execute(
            'SELECT user_id FROM posts WHERE post_id = :id',
            { id }
        );
        if (!ownerCheck.rows || ownerCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Postingan tidak ditemukan.' });
        }
        if (ownerCheck.rows[0].USER_ID !== req.user.user_id && req.user.role !== 'admin') {
            return res.status(403).json({ success: false, message: 'Anda tidak berhak mengedit postingan ini.' });
        }

        // Update (trigger trg_posts_bu will set updated_at & is_edited)
        await db.execute(
            'UPDATE posts SET content = :content WHERE post_id = :id',
            { content: content.trim(), id },
            { autoCommit: true }
        );

        res.json({ success: true, message: 'Postingan berhasil diperbarui.' });

    } catch (err) { next(err); }
};

/**
 * DELETE /api/posts/:id
 * Delete own post (or admin can delete any post)
 */
const deletePost = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Find post and check ownership
        const postResult = await db.execute(
            'SELECT user_id, image_url FROM posts WHERE post_id = :id',
            { id }
        );
        if (!postResult.rows || postResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Postingan tidak ditemukan.' });
        }

        const post = postResult.rows[0];
        if (post.USER_ID !== req.user.user_id && req.user.role !== 'admin') {
            return res.status(403).json({ success: false, message: 'Anda tidak berhak menghapus postingan ini.' });
        }

        // Delete post (CASCADE will handle comments, likes, notifications, reports)
        await db.execute('DELETE FROM posts WHERE post_id = :id', { id }, { autoCommit: true });

        // Remove associated image file if it exists
        if (post.IMAGE_URL) {
            const filePath = path.join(__dirname, '..', post.IMAGE_URL);
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
        }

        res.json({ success: true, message: 'Postingan berhasil dihapus.' });

    } catch (err) { next(err); }
};

/**
 * POST /api/posts/:id/like
 * Toggle like/unlike on a post
 */
const toggleLike = async (req, res, next) => {
    try {
        const { id }     = req.params;
        const user_id    = req.user.user_id;

        // Check if post exists
        const postCheck = await db.execute(
            'SELECT post_id FROM posts WHERE post_id = :id',
            { id }
        );
        if (!postCheck.rows || postCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Postingan tidak ditemukan.' });
        }

        // Check if already liked
        const likeCheck = await db.execute(
            'SELECT like_id FROM likes WHERE post_id = :pid AND user_id = :uid',
            { pid: id, uid: user_id }
        );

        let action;
        if (likeCheck.rows && likeCheck.rows.length > 0) {
            // Unlike
            await db.execute(
                'DELETE FROM likes WHERE post_id = :pid AND user_id = :uid',
                { pid: id, uid: user_id },
                { autoCommit: true }
            );
            action = 'UNLIKED';
        } else {
            // Like (trigger will auto-create notification)
            await db.execute(
                'INSERT INTO likes (post_id, user_id) VALUES (:pid, :uid)',
                { pid: id, uid: user_id },
                { autoCommit: true }
            );
            action = 'LIKED';
        }

        // Get updated like count
        const countResult = await db.execute(
            'SELECT COUNT(*) AS cnt FROM likes WHERE post_id = :id',
            { id }
        );

        res.json({
            success: true,
            action,
            data: { like_count: countResult.rows[0].CNT },
        });

    } catch (err) { next(err); }
};

/**
 * POST /api/posts/:id/comment
 * Add a comment to a post (trigger auto-creates notification)
 */
const addComment = async (req, res, next) => {
    try {
        const { id }          = req.params;
        const { comment_text } = req.body;

        if (!comment_text || comment_text.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Komentar tidak boleh kosong.' });
        }
        if (comment_text.length > 1000) {
            return res.status(400).json({ success: false, message: 'Komentar maksimal 1000 karakter.' });
        }

        // Check if post exists
        const postCheck = await db.execute('SELECT post_id FROM posts WHERE post_id = :id', { id });
        if (!postCheck.rows || postCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Postingan tidak ditemukan.' });
        }

        const result = await db.execute(
            `INSERT INTO comments (post_id, user_id, comment_text)
             VALUES (:pid, :uid, :text)
             RETURNING comment_id INTO :cid`,
            {
                pid:  id,
                uid:  req.user.user_id,
                text: comment_text.trim(),
                cid:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
            },
            { autoCommit: true }
        );

        res.status(201).json({
            success: true,
            message: 'Komentar berhasil ditambahkan.',
            data: {
                comment_id:   result.outBinds.cid[0],
                comment_text: comment_text.trim(),
                username:     req.user.username,
            },
        });

    } catch (err) { next(err); }
};

/**
 * DELETE /api/posts/:id/comments/:cid
 * Delete a comment
 */
const deleteComment = async (req, res, next) => {
    try {
        const { cid } = req.params;

        const check = await db.execute(
            'SELECT user_id FROM comments WHERE comment_id = :id',
            { id: cid }
        );
        if (!check.rows || check.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Komentar tidak ditemukan.' });
        }
        if (check.rows[0].USER_ID !== req.user.user_id && req.user.role !== 'admin') {
            return res.status(403).json({ success: false, message: 'Anda tidak berhak menghapus komentar ini.' });
        }

        await db.execute('DELETE FROM comments WHERE comment_id = :id', { id: cid }, { autoCommit: true });
        res.json({ success: true, message: 'Komentar berhasil dihapus.' });

    } catch (err) { next(err); }
};

module.exports = { getTimeline, getPost, createPost, updatePost, deletePost, toggleLike, addComment, deleteComment };
