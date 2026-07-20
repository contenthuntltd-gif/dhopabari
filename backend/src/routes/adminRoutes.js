const express = require('express');
const ctrl = require('../controllers/adminController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate, authorize('ADMIN'));

router.get('/dashboard', ctrl.dashboard);
router.get('/reports', ctrl.reports);
router.get('/customers', ctrl.listCustomers);
router.patch('/customers/:id/block', ctrl.setCustomerBlocked);
router.get('/settings', ctrl.getSettings);
router.put('/settings/:key', ctrl.putSetting);

module.exports = router;
