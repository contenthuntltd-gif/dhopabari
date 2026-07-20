const express = require('express');
const ctrl = require('../controllers/receiptController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.post('/pickup', authorize('RIDER', 'ADMIN'), ctrl.createPickupReceipt);
router.post('/delivery', authorize('RIDER', 'ADMIN'), ctrl.createDeliveryReceipt);
router.post('/payment', ctrl.createPaymentReceipt);
router.patch('/:id/confirm-customer', authorize('CUSTOMER'), ctrl.confirmCustomerReceipt);
router.get('/', authorize('ADMIN'), ctrl.searchReceipts); // Memo Center
router.get('/order/:orderId', ctrl.listForOrder);
router.get('/:id', ctrl.getReceipt);
router.post('/:id/email', ctrl.emailReceipt);

module.exports = router;
