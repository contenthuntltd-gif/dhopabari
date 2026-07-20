const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');
const { nextReceiptNumber } = require('../utils/receiptNumber');
const { sendReceiptEmail } = require('../services/emailService');

const ORDER_INCLUDE = {
  items: true,
  address: true,
  service: true,
  rider: { include: { user: true } },
  customer: true,
};

function assertOrderAccess(req, order) {
  const isOwner = req.user.role === 'CUSTOMER' && order.customerId === req.user.id;
  const isRider = req.user.role === 'RIDER' && order.riderId === req.user.riderProfile?.id;
  const isAdmin = req.user.role === 'ADMIN';
  if (!isOwner && !isRider && !isAdmin) {
    const err = new Error('You do not have access to this order');
    err.status = 403;
    throw err;
  }
}

function itemsSnapshot(order) {
  return order.items.map((i) => ({
    itemName: i.itemName,
    service: order.service?.name || '',
    quantity: i.quantity,
    unitPrice: i.unitPrice,
    total: i.total,
  }));
}

function estimatedDeliveryLabel(order) {
  return order.deliveryType === 'EXPRESS' ? '২ দিনের মধ্যে' : '৩-৫ দিন';
}

// POST /api/receipts/pickup  { orderId, specialInstructions?, stainNotes?, fragileNotes?, otherNotes? }
// Rider or admin only — generates the pickup receipt and marks it confirmed immediately
// (this endpoint IS the "Pickup Confirmation" action; there's no separate draft state).
const createPickupReceipt = asyncHandler(async (req, res) => {
  const { orderId, specialInstructions, stainNotes, fragileNotes, otherNotes } = req.body;
  const order = await prisma.order.findUnique({ where: { id: orderId }, include: ORDER_INCLUDE });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  if (req.user.role !== 'ADMIN' && !(req.user.role === 'RIDER' && order.riderId === req.user.riderProfile?.id)) {
    res.status(403);
    throw new Error('Only the assigned rider or an admin can confirm pickup');
  }

  const items = itemsSnapshot(order);
  const totalQuantity = items.reduce((sum, i) => sum + i.quantity, 0);

  const receipt = await prisma.$transaction(async (tx) => {
    const receiptNumber = await nextReceiptNumber(tx);
    return tx.receipt.create({
      data: {
        receiptNumber,
        type: 'PICKUP',
        orderId: order.id,
        customerName: order.customer.name || '',
        customerPhone: order.customer.phone,
        customerId: order.customerId,
        riderName: order.rider?.user?.name || null,
        riderPhone: order.rider?.user?.phone || null,
        riderId: order.riderId,
        pickupAddress: `${order.address.addressLine}, ${order.address.area}`,
        pickupAt: new Date(),
        estimatedDelivery: estimatedDeliveryLabel(order),
        items,
        totalQuantity,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        expressCharge: order.expressCharge,
        discount: order.discount,
        grandTotal: order.total,
        specialInstructions,
        stainNotes,
        fragileNotes,
        otherNotes,
        confirmedAt: new Date(),
      },
    });
  });

  res.status(201).json({ ok: true, receipt });
});

// POST /api/receipts/delivery  { orderId, deliveredBy? }
// Rider or admin only — generates the delivery receipt.
const createDeliveryReceipt = asyncHandler(async (req, res) => {
  const { orderId, deliveredBy } = req.body;
  const order = await prisma.order.findUnique({ where: { id: orderId }, include: ORDER_INCLUDE });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  if (req.user.role !== 'ADMIN' && !(req.user.role === 'RIDER' && order.riderId === req.user.riderProfile?.id)) {
    res.status(403);
    throw new Error('Only the assigned rider or an admin can confirm delivery');
  }

  const items = itemsSnapshot(order);
  const totalQuantity = items.reduce((sum, i) => sum + i.quantity, 0);

  const receipt = await prisma.$transaction(async (tx) => {
    const receiptNumber = await nextReceiptNumber(tx);
    return tx.receipt.create({
      data: {
        receiptNumber,
        type: 'DELIVERY',
        orderId: order.id,
        customerName: order.customer.name || '',
        customerPhone: order.customer.phone,
        customerId: order.customerId,
        riderName: order.rider?.user?.name || null,
        riderPhone: order.rider?.user?.phone || null,
        riderId: order.riderId,
        deliveredBy: deliveredBy || order.rider?.user?.name || null,
        deliveredAt: new Date(),
        items,
        totalQuantity,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        expressCharge: order.expressCharge,
        discount: order.discount,
        grandTotal: order.total,
        confirmedAt: new Date(),
      },
    });
  });

  res.status(201).json({ ok: true, receipt });
});

// POST /api/receipts/payment  { orderId }
// Admin or the customer on the order — generated automatically once
// payment is confirmed (e.g. right after createOrder for COD, or after a
// gateway webhook marks paymentStatus PAID).
const createPaymentReceipt = asyncHandler(async (req, res) => {
  const { orderId } = req.body;
  const order = await prisma.order.findUnique({ where: { id: orderId }, include: ORDER_INCLUDE });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  assertOrderAccess(req, order);

  const items = itemsSnapshot(order);
  const totalQuantity = items.reduce((sum, i) => sum + i.quantity, 0);

  const receipt = await prisma.$transaction(async (tx) => {
    const receiptNumber = await nextReceiptNumber(tx);
    return tx.receipt.create({
      data: {
        receiptNumber,
        type: 'PAYMENT',
        orderId: order.id,
        customerName: order.customer.name || '',
        customerPhone: order.customer.phone,
        customerId: order.customerId,
        items,
        totalQuantity,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        expressCharge: order.expressCharge,
        discount: order.discount,
        grandTotal: order.total,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        confirmedAt: new Date(),
      },
    });
  });

  res.status(201).json({ ok: true, receipt });
});

// PATCH /api/receipts/:id/confirm-customer — customer confirms they received the delivery
const confirmCustomerReceipt = asyncHandler(async (req, res) => {
  const receipt = await prisma.receipt.findUnique({ where: { id: req.params.id }, include: { order: true } });
  if (!receipt) {
    res.status(404);
    throw new Error('Receipt not found');
  }
  if (req.user.role !== 'CUSTOMER' || receipt.order.customerId !== req.user.id) {
    res.status(403);
    throw new Error('Only the customer on this order can confirm it');
  }
  const updated = await prisma.receipt.update({ where: { id: receipt.id }, data: { customerConfirmedAt: new Date() } });
  res.json({ ok: true, receipt: updated });
});

// GET /api/receipts  (admin only) — Memo Center search
// ?memoNumber=&orderId=&customer=&rider=&phone=&date=YYYY-MM-DD
const searchReceipts = asyncHandler(async (req, res) => {
  const { memoNumber, orderId, customer, rider, phone, date } = req.query;
  const where = {};
  if (memoNumber) where.receiptNumber = { contains: memoNumber, mode: 'insensitive' };
  if (orderId) where.orderId = { contains: orderId, mode: 'insensitive' };
  if (customer) where.customerName = { contains: customer, mode: 'insensitive' };
  if (rider) where.riderName = { contains: rider, mode: 'insensitive' };
  if (phone) where.customerPhone = { contains: phone, mode: 'insensitive' };
  if (date) {
    const start = new Date(date);
    const end = new Date(start);
    end.setDate(end.getDate() + 1);
    where.createdAt = { gte: start, lt: end };
  }
  const receipts = await prisma.receipt.findMany({ where, orderBy: { createdAt: 'desc' }, take: 200 });
  res.json({ ok: true, receipts });
});

// GET /api/receipts/order/:orderId — every receipt (pickup + delivery) for an order
const listForOrder = asyncHandler(async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.orderId } });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  assertOrderAccess(req, order);
  const receipts = await prisma.receipt.findMany({ where: { orderId: order.id }, orderBy: { createdAt: 'asc' } });
  res.json({ ok: true, receipts });
});

// GET /api/receipts/:id
const getReceipt = asyncHandler(async (req, res) => {
  const receipt = await prisma.receipt.findUnique({ where: { id: req.params.id }, include: { order: true } });
  if (!receipt) {
    res.status(404);
    throw new Error('Receipt not found');
  }
  assertOrderAccess(req, receipt.order);
  res.json({ ok: true, receipt });
});

// POST /api/receipts/:id/email  { email, pdfBase64 }
// The PDF itself is rendered client-side (same layout as the on-screen
// receipt) and posted here as base64 so this endpoint only has to relay it.
const emailReceipt = asyncHandler(async (req, res) => {
  const { email, pdfBase64 } = req.body;
  if (!email || !pdfBase64) {
    res.status(400);
    throw new Error('email and pdfBase64 are required');
  }
  const receipt = await prisma.receipt.findUnique({ where: { id: req.params.id }, include: { order: true } });
  if (!receipt) {
    res.status(404);
    throw new Error('Receipt not found');
  }
  assertOrderAccess(req, receipt.order);
  await sendReceiptEmail({ to: email, receiptNumber: receipt.receiptNumber, pdfBase64 });
  res.json({ ok: true });
});

module.exports = {
  createPickupReceipt,
  createDeliveryReceipt,
  createPaymentReceipt,
  confirmCustomerReceipt,
  searchReceipts,
  listForOrder,
  getReceipt,
  emailReceipt,
};
