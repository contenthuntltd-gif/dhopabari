const express = require('express');
const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const paymentService = require('../services/paymentService');

const router = express.Router();
router.use(authenticate);

// POST /api/payments/initiate  { orderId, method: 'BKASH'|'NAGAD'|'SSLCOMMERZ' }
router.post(
  '/initiate',
  asyncHandler(async (req, res) => {
    const { orderId, method } = req.body;
    const order = await prisma.order.findUnique({ where: { id: orderId }, include: { customer: true } });
    if (!order || order.customerId !== req.user.id) {
      res.status(404);
      throw new Error('Order not found');
    }

    const initiators = {
      BKASH: paymentService.initiateBkashPayment,
      NAGAD: paymentService.initiateNagadPayment,
      SSLCOMMERZ: paymentService.initiateSslcommerzPayment,
    };
    const initiate = initiators[method];
    if (!initiate) {
      res.status(400);
      throw new Error('Unsupported payment method — use BKASH, NAGAD or SSLCOMMERZ');
    }

    const result = await initiate({ orderId: order.id, amount: order.total, customer: order.customer });
    res.json({ ok: true, ...result });
  })
);

module.exports = router;
