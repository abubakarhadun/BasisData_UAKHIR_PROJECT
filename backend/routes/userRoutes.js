// routes/userRoutes.js
const express  = require('express');
const router   = express.Router();
const upload   = require('../config/multer');
const { authenticate, optionalAuth } = require('../middleware/auth');
const {
    getProfile, updateProfile, changePassword,
    followUser, getFollowers, getFollowing, searchUsers
} = require('../controllers/userController');

router.get('/search',                          authenticate, searchUsers);
router.get('/:username',                       optionalAuth, getProfile);
router.put('/profile/edit',  authenticate, upload.single('profile_picture'), updateProfile);
router.put('/profile/password', authenticate, changePassword);
router.post('/:id/follow',     authenticate, followUser);
router.get('/:id/followers',   optionalAuth, getFollowers);
router.get('/:id/following',   optionalAuth, getFollowing);

module.exports = router;


// ============================================================
// routes/notificationRoutes.js
// ============================================================
const nRouter = express.Router();
const { getNotifications, markAllRead, markOneRead } = require('../controllers/notificationController');

nRouter.get('/',              authenticate, getNotifications);
nRouter.put('/read-all',      authenticate, markAllRead);
nRouter.put('/:id/read',      authenticate, markOneRead);

module.exports.notifRouter = nRouter;


// ============================================================
// routes/reportRoutes.js
// ============================================================
const rRouter = express.Router();
const { submitReport } = require('../controllers/notificationController');

rRouter.post('/', authenticate, submitReport);

module.exports.reportRouter = rRouter;


// ============================================================
// routes/adminRoutes.js
// ============================================================
const aRouter = express.Router();
const { authenticate: auth, authorizeAdmin } = require('../middleware/auth');
const {
    getAllUsers, banUser, getAllPosts, getAllReports, updateReport, getDashboardStats
} = require('../controllers/adminController');

const adminAuth = [auth, authorizeAdmin];

aRouter.get('/stats',            ...adminAuth, getDashboardStats);
aRouter.get('/users',            ...adminAuth, getAllUsers);
aRouter.post('/users/:id/ban',   ...adminAuth, banUser);
aRouter.get('/posts',            ...adminAuth, getAllPosts);
aRouter.get('/reports',          ...adminAuth, getAllReports);
aRouter.put('/reports/:id',      ...adminAuth, updateReport);

module.exports.adminRouter = aRouter;
