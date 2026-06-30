// routes/postRoutes.js
const express    = require('express');
const router     = express.Router();
const upload     = require('../config/multer');
const { authenticate, optionalAuth } = require('../middleware/auth');
const {
    getTimeline, getPost, createPost, updatePost, deletePost,
    toggleLike, addComment, deleteComment
} = require('../controllers/postController');

router.get('/',                                   optionalAuth, getTimeline);
router.get('/:id',                                optionalAuth, getPost);
router.post('/',    authenticate, upload.single('image'), createPost);
router.put('/:id',  authenticate,                          updatePost);
router.delete('/:id', authenticate,                        deletePost);
router.post('/:id/like',          authenticate, toggleLike);
router.post('/:id/comment',       authenticate, addComment);
router.delete('/:id/comments/:cid', authenticate, deleteComment);

module.exports = router;
