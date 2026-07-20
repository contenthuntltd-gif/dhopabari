const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');

// POST /api/coupons/validate  { code, subtotal }
const validateCoupon = asyncHandler(async (req, res) => {
  const { code, subtotal } = req.body;
  const coupon = await prisma.coupon.findUnique({ where: { code } });
  if (!coupon || !coupon.isActive) {
    res.status(404);
    throw new Error('Invalid or inactive coupon');
  }
  if (coupon.expiresAt && coupon.expiresAt < new Date()) {
    res.status(400);
    throw new Error('Coupon has expired');
  }
  if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
    res.status(400);
    throw new Error('Coupon usage limit reached');
  }
  if (Number(subtotal) < coupon.minOrderAmount) {
    res.status(400);
    throw new Error(`Minimum order amount for this coupon is ৳${coupon.minOrderAmount}`);
  }
  let discount = coupon.type === 'PERCENT' ? Math.round((Number(subtotal) * coupon.value) / 100) : coupon.value;
  if (coupon.maxDiscount) discount = Math.min(discount, coupon.maxDiscount);
  res.json({ ok: true, coupon, discount });
});

// GET /api/coupons  — admin
const listCoupons = asyncHandler(async (req, res) => {
  const coupons = await prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } });
  res.json({ ok: true, coupons });
});

// POST /api/coupons  — admin  { code, type, value, minOrderAmount, maxDiscount, usageLimit, expiresAt }
const createCoupon = asyncHandler(async (req, res) => {
  const coupon = await prisma.coupon.create({ data: req.body });
  res.status(201).json({ ok: true, coupon });
});

// PATCH /api/coupons/:id  — admin
const updateCoupon = asyncHandler(async (req, res) => {
  const coupon = await prisma.coupon.update({ where: { id: req.params.id }, data: req.body });
  res.json({ ok: true, coupon });
});

// DELETE /api/coupons/:id — admin (soft delete via isActive)
const deactivateCoupon = asyncHandler(async (req, res) => {
  const coupon = await prisma.coupon.update({ where: { id: req.params.id }, data: { isActive: false } });
  res.json({ ok: true, coupon });
});

module.exports = { validateCoupon, listCoupons, createCoupon, updateCoupon, deactivateCoupon };
