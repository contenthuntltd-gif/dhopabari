const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');
const { generateOrderNumber } = require('../utils/orderNumber');
const { notifyOrderStatusChange, notifyUser } = require('../services/notify');
const { textInvoicePdf } = require('../utils/pdf');
const { isOpenNow, OFF_HOURS_MESSAGE_BN } = require('../utils/businessHours');

const EXPRESS_CHARGE = 50;

// FINAL master order status flow — six steps, forward-only, no skipping.
// CONFIRMED -> PICKED_UP -> CLEANING -> PACKAGING_DONE -> OUT_FOR_DELIVERY -> DELIVERED
const STATUS_FLOW = [
  'CONFIRMED',
  'PICKED_UP',
  'CLEANING',
  'PACKAGING_DONE',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
];

// Riders may only move an order into these statuses — cleaning/packaging
// is laundry-staff/admin territory (see updateStatus).
const RIDER_ALLOWED_STATUSES = ['PICKED_UP', 'OUT_FOR_DELIVERY', 'DELIVERED'];

// An order can only be cancelled before cleaning has started — once the
// laundry has begun processing the clothes, cancellation is no longer
// offered (not part of the spec's six statuses, but a necessary guard so
// CANCELLED — the one allowed exception status — isn't reachable from an
// arbitrary point mid-flow).
const CANCELLABLE_STATUSES = ['CONFIRMED', 'PICKED_UP'];

const ORDER_INCLUDE = {
  items: true,
  address: true,
  service: true,
  coupon: true,
  rider: { include: { user: true } },
  customer: true,
  statusHistory: { orderBy: { createdAt: 'asc' } },
};

// POST /api/orders
// { serviceId, addressId, pickupDate, pickupTime, items: [{priceItemId, quantity}], couponCode?, paymentMethod, deliveryType? }
const createOrder = asyncHandler(async (req, res) => {
  const { serviceId, addressId, pickupDate, pickupTime, items, couponCode, paymentMethod, notes, deliveryType } = req.body;
  const resolvedDeliveryType = deliveryType === 'EXPRESS' ? 'EXPRESS' : 'FREE';

  if (!serviceId || !addressId || !pickupDate || !pickupTime || !Array.isArray(items) || items.length === 0) {
    res.status(400);
    throw new Error('serviceId, addressId, pickupDate, pickupTime and at least one item are required');
  }

  const address = await prisma.address.findUnique({ where: { id: addressId } });
  if (!address || address.userId !== req.user.id) {
    res.status(400);
    throw new Error('Invalid address');
  }

  const priceItemIds = items.map((i) => i.priceItemId);
  const priceItems = await prisma.priceItem.findMany({ where: { id: { in: priceItemIds } } });
  const priceItemMap = new Map(priceItems.map((p) => [p.id, p]));

  let subtotal = 0;
  const orderItemsData = items.map((i) => {
    const priceItem = priceItemMap.get(i.priceItemId);
    if (!priceItem) throw Object.assign(new Error(`Unknown price item: ${i.priceItemId}`), { status: 400 });
    const qty = Number(i.quantity) || 0;
    if (qty <= 0) throw Object.assign(new Error('Item quantity must be greater than 0'), { status: 400 });
    const total = priceItem.price * qty;
    subtotal += total;
    return {
      priceItemId: priceItem.id,
      itemName: priceItem.name,
      quantity: qty,
      unitPrice: priceItem.price,
      total,
    };
  });

  let discount = 0;
  let coupon = null;
  if (couponCode) {
    coupon = await prisma.coupon.findUnique({ where: { code: couponCode } });
    if (!coupon || !coupon.isActive) throw Object.assign(new Error('Invalid or expired coupon'), { status: 400 });
    if (coupon.expiresAt && coupon.expiresAt < new Date()) throw Object.assign(new Error('Coupon has expired'), { status: 400 });
    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) throw Object.assign(new Error('Coupon usage limit reached'), { status: 400 });
    if (subtotal < coupon.minOrderAmount) throw Object.assign(new Error(`Minimum order amount for this coupon is ৳${coupon.minOrderAmount}`), { status: 400 });
    discount = coupon.type === 'PERCENT' ? Math.round((subtotal * coupon.value) / 100) : coupon.value;
    if (coupon.maxDiscount) discount = Math.min(discount, coupon.maxDiscount);
  }

  const deliveryFee = 0; // pickup & delivery are always free per business rules
  const expressCharge = resolvedDeliveryType === 'EXPRESS' ? EXPRESS_CHARGE : 0;
  const total = Math.max(0, subtotal + deliveryFee + expressCharge - discount);
  const placedOffHours = !isOpenNow();

  const order = await prisma.$transaction(async (tx) => {
    const created = await tx.order.create({
      data: {
        orderNumber: generateOrderNumber(),
        customerId: req.user.id,
        serviceId,
        addressId,
        pickupDate: new Date(pickupDate),
        pickupTime,
        deliveryType: resolvedDeliveryType,
        placedOffHours,
        subtotal,
        deliveryFee,
        expressCharge,
        discount,
        total,
        couponId: coupon?.id,
        paymentMethod: paymentMethod || 'COD',
        notes,
        items: { create: orderItemsData },
        statusHistory: { create: { status: 'CONFIRMED', changedById: req.user.id, changedByRole: req.user.role } },
      },
      include: ORDER_INCLUDE,
    });
    if (coupon) {
      await tx.coupon.update({ where: { id: coupon.id }, data: { usedCount: { increment: 1 } } });
    }
    return created;
  });

  await notifyOrderStatusChange(order, req.user.fcmToken).catch(() => {});
  res.status(201).json({
    ok: true,
    order,
    // The order is accepted either way — this just tells the client whether
    // to show the "our team will confirm during business hours" banner.
    offHoursMessage: placedOffHours ? OFF_HOURS_MESSAGE_BN : null,
  });
});

// GET /api/orders  (customer: own orders · rider: assigned orders · admin: all, with filters)
const listOrders = asyncHandler(async (req, res) => {
  const { status, search } = req.query;
  let where = {};

  if (req.user.role === 'CUSTOMER') {
    where.customerId = req.user.id;
  } else if (req.user.role === 'RIDER') {
    if (!req.user.riderProfile) return res.json({ ok: true, orders: [] });
    where.riderId = req.user.riderProfile.id;
  }
  // ADMIN sees everything, optionally filtered

  if (status) where.status = status;
  if (search) {
    where.OR = [
      { orderNumber: { contains: search, mode: 'insensitive' } },
      { customer: { name: { contains: search, mode: 'insensitive' } } },
      { customer: { phone: { contains: search, mode: 'insensitive' } } },
    ];
  }

  const orders = await prisma.order.findMany({ where, include: ORDER_INCLUDE, orderBy: { createdAt: 'desc' } });
  res.json({ ok: true, orders });
});

// GET /api/orders/:id
const getOrder = asyncHandler(async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id }, include: ORDER_INCLUDE });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  const isOwner = req.user.role === 'CUSTOMER' && order.customerId === req.user.id;
  const isRider = req.user.role === 'RIDER' && order.riderId === req.user.riderProfile?.id;
  const isAdmin = req.user.role === 'ADMIN';
  if (!isOwner && !isRider && !isAdmin) {
    res.status(403);
    throw new Error('You do not have access to this order');
  }
  res.json({ ok: true, order });
});

// PATCH /api/orders/:id/status  { status, note? }  — admin or assigned rider.
// Forward-only, one step at a time — skipping steps is rejected outright.
// Riders are further restricted to RIDER_ALLOWED_STATUSES; cleaning and
// packaging can only be advanced by an admin (acting as laundry staff —
// this schema has no separate staff role).
const updateStatus = asyncHandler(async (req, res) => {
  const { status, note } = req.body;
  if (!STATUS_FLOW.includes(status)) {
    res.status(400);
    throw new Error('Invalid status');
  }
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  const isRider = req.user.role === 'RIDER' && order.riderId === req.user.riderProfile?.id;
  const isAdmin = req.user.role === 'ADMIN';
  if (!isRider && !isAdmin) {
    res.status(403);
    throw new Error('Only the assigned rider or an admin can update this order');
  }

  const currentIndex = STATUS_FLOW.indexOf(order.status);
  if (currentIndex === -1) {
    res.status(400);
    throw new Error(`Order is ${order.status.toLowerCase()} and cannot be moved further`);
  }
  if (currentIndex === STATUS_FLOW.length - 1) {
    res.status(400);
    throw new Error('This order has already been delivered');
  }
  const nextStatus = STATUS_FLOW[currentIndex + 1];
  if (status !== nextStatus) {
    res.status(400);
    throw new Error(`Status must move forward one step at a time — next allowed status is ${nextStatus}`);
  }
  if (isRider && !RIDER_ALLOWED_STATUSES.includes(nextStatus)) {
    res.status(403);
    throw new Error('Riders can only update pickup/delivery statuses — cleaning and packaging are updated by laundry staff/admin');
  }

  const updated = await prisma.$transaction(async (tx) => {
    const u = await tx.order.update({
      where: { id: order.id },
      data: {
        status,
        ...(status === 'DELIVERED' ? { deliveryDate: new Date() } : {}),
      },
      include: ORDER_INCLUDE,
    });
    await tx.orderStatusLog.create({ data: { orderId: order.id, status, note, changedById: req.user.id, changedByRole: req.user.role } });
    if (status === 'DELIVERED' && u.riderId) {
      await tx.riderProfile.update({ where: { id: u.riderId }, data: { totalDeliveries: { increment: 1 } } });
    }
    return u;
  });

  await notifyOrderStatusChange(updated, updated.customer.fcmToken).catch(() => {});
  res.json({ ok: true, order: updated });
});

// PATCH /api/orders/:id/assign-rider  { riderId }  — admin only. Assigning
// a rider does NOT change the order status — the rider still has to mark
// the order picked up themselves once they've collected the clothes.
const assignRider = asyncHandler(async (req, res) => {
  const { riderId } = req.body;
  const rider = await prisma.riderProfile.findUnique({ where: { id: riderId }, include: { user: true } });
  if (!rider) {
    res.status(404);
    throw new Error('Rider not found');
  }
  const order = await prisma.order.update({
    where: { id: req.params.id },
    data: { riderId },
    include: ORDER_INCLUDE,
  });
  await notifyUser({
    userId: rider.userId,
    type: 'ORDER_UPDATE',
    title: `New pickup: ${order.orderNumber}`,
    titleBn: `নতুন পিকআপ: ${order.orderNumber}`,
    body: 'You have been assigned a new pickup',
    bodyBn: 'আপনাকে একটি নতুন পিকআপ দেওয়া হয়েছে',
    data: { orderId: order.id },
    fcmToken: rider.user.fcmToken,
  }).catch(() => {});
  res.json({ ok: true, order });
});

// DELETE /api/orders/:id  (cancel)
const cancelOrder = asyncHandler(async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  const isOwner = req.user.role === 'CUSTOMER' && order.customerId === req.user.id;
  const isAdmin = req.user.role === 'ADMIN';
  if (!isOwner && !isAdmin) {
    res.status(403);
    throw new Error('You cannot cancel this order');
  }
  if (!CANCELLABLE_STATUSES.includes(order.status)) {
    res.status(400);
    throw new Error(order.status === 'CANCELLED' ? 'Order is already cancelled' : 'This order can no longer be cancelled — cleaning has already started');
  }
  const updated = await prisma.$transaction(async (tx) => {
    const u = await tx.order.update({ where: { id: order.id }, data: { status: 'CANCELLED' }, include: ORDER_INCLUDE });
    await tx.orderStatusLog.create({ data: { orderId: order.id, status: 'CANCELLED', changedById: req.user.id, changedByRole: req.user.role } });
    return u;
  });
  await notifyOrderStatusChange(updated, updated.customer.fcmToken).catch(() => {});
  res.json({ ok: true, order: updated });
});

// GET /api/orders/:id/invoice.pdf
const getInvoice = asyncHandler(async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id }, include: ORDER_INCLUDE });
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }
  const isOwner = req.user.role === 'CUSTOMER' && order.customerId === req.user.id;
  const isRider = req.user.role === 'RIDER' && order.riderId === req.user.riderProfile?.id;
  const isAdmin = req.user.role === 'ADMIN';
  if (!isOwner && !isRider && !isAdmin) {
    res.status(403);
    throw new Error('You do not have access to this order');
  }
  const lines = [
    'Dhopa Bari — Invoice',
    `Order: ${order.orderNumber}`,
    `Customer: ${order.customer.name || ''} (${order.customer.phone})`,
    `Date: ${order.createdAt.toISOString().slice(0, 10)}`,
    '',
    'Items:',
    ...order.items.map((i) => `  ${i.itemName} x${i.quantity} — ৳${i.total}`),
    '',
    `Subtotal: ৳${order.subtotal}`,
    `Discount: -৳${order.discount}`,
    `Delivery: ${order.deliveryFee === 0 ? 'FREE' : `৳${order.deliveryFee}`}`,
    ...(order.expressCharge > 0 ? [`Express Delivery: ৳${order.expressCharge}`] : []),
    `Total: ৳${order.total}`,
    '',
    `Payment: ${order.paymentMethod} (${order.paymentStatus})`,
  ];
  const pdf = textInvoicePdf(lines);
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename="${order.orderNumber}.pdf"`);
  res.send(pdf);
});

module.exports = { createOrder, listOrders, getOrder, updateStatus, assignRider, cancelOrder, getInvoice };
