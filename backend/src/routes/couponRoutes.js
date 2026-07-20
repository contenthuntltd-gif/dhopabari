const express = require('express');
const ctrl = require('../controllers/couponController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.post('/validate', ctrl.validateCoupon);
router.get('/', authorize('ADMIN'), ctrl.listCoupons);
router.post('/', authorize('ADMIN'), ctrl.createCoupon);
router.patch('/:id', authorize('ADMIN'), ctrl.updateCoupon);
router.delete('/:id', authorize('ADMIN'), ctrl.deactivateCoupon);

module.exports = router;
