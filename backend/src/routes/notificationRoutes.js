const express = require('express');
const ctrl = require('../controllers/notificationController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/', ctrl.listMine);
router.patch('/:id/read', ctrl.markRead);
router.put('/device-token', ctrl.registerDeviceToken);
router.post('/broadcast', authorize('ADMIN'), ctrl.broadcast);

module.exports = router;
