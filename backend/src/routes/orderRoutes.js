const express = require('express');
const ctrl = require('../controllers/orderController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.post('/', ctrl.createOrder);
router.get('/', ctrl.listOrders);
router.get('/:id', ctrl.getOrder);
router.get('/:id/invoice.pdf', ctrl.getInvoice);
router.patch('/:id/status', ctrl.updateStatus);
router.patch('/:id/assign-rider', authorize('ADMIN'), ctrl.assignRider);
router.delete('/:id', ctrl.cancelOrder);

module.exports = router;
