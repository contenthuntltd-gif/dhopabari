const express = require('express');
const ctrl = require('../controllers/riderController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

// Rider self-service
router.get('/me/dashboard', authorize('RIDER'), ctrl.myDashboard);
router.patch('/me/online', authorize('RIDER'), ctrl.setOnlineStatus);
router.patch('/me/location', authorize('RIDER'), ctrl.updateLocation);
router.get('/me/earnings', authorize('RIDER'), ctrl.myEarnings);
router.post('/me/withdrawals', authorize('RIDER'), ctrl.requestWithdrawal);

// Admin management
router.get('/', authorize('ADMIN'), ctrl.listRiders);
router.post('/', authorize('ADMIN'), ctrl.createRider);
router.patch('/:id', authorize('ADMIN'), ctrl.updateRider);
router.delete('/:id', authorize('ADMIN'), ctrl.deleteRider);

module.exports = router;
