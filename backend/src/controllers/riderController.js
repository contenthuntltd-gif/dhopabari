const asyncHandler = require('express-async-handler');
const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');

function publicUser(user) {
  if (!user) return user;
  const { passwordHash, ...safe } = user;
  return safe;
}

// ── Rider self-service ────────────────────────────────────

// GET /api/riders/me/dashboard
const myDashboard = asyncHandler(async (req, res) => {
  const riderId = req.user.riderProfile?.id;
  if (!riderId) {
    res.status(400);
    throw new Error('This account has no rider profile');
  }
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const [todaysPickups, todaysDeliveries, activeOrders] = await Promise.all([
    prisma.order.count({ where: { riderId, pickupDate: { gte: today, lt: tomorrow } } }),
    prisma.order.count({ where: { riderId, status: 'DELIVERED', deliveryDate: { gte: today, lt: tomorrow } } }),
    prisma.order.findMany({
      where: { riderId, status: { notIn: ['DELIVERED', 'CANCELLED'] } },
      include: { customer: true, address: true, service: true },
      orderBy: { createdAt: 'asc' },
    }),
  ]);

  res.json({
    ok: true,
    rider: req.user.riderProfile,
    todaysPickups,
    todaysDeliveries,
    activeOrders,
  });
});

// PATCH /api/riders/me/online  { isOnline }
const setOnlineStatus = asyncHandler(async (req, res) => {
  const riderId = req.user.riderProfile?.id;
  if (!riderId) {
    res.status(400);
    throw new Error('This account has no rider profile');
  }
  const rider = await prisma.riderProfile.update({
    where: { id: riderId },
    data: { isOnline: Boolean(req.body.isOnline) },
  });
  res.json({ ok: true, rider });
});

// PATCH /api/riders/me/location  { lat, lng }
const updateLocation = asyncHandler(async (req, res) => {
  const riderId = req.user.riderProfile?.id;
  if (!riderId) {
    res.status(400);
    throw new Error('This account has no rider profile');
  }
  const { lat, lng } = req.body;
  const rider = await prisma.riderProfile.update({
    where: { id: riderId },
    data: { currentLat: lat, currentLng: lng },
  });
  res.json({ ok: true, rider });
});

// GET /api/riders/me/earnings
const myEarnings = asyncHandler(async (req, res) => {
  const riderId = req.user.riderProfile?.id;
  if (!riderId) {
    res.status(400);
    throw new Error('This account has no rider profile');
  }
  const rider = await prisma.riderProfile.findUnique({ where: { id: riderId } });
  const withdrawals = await prisma.withdrawalRequest.findMany({
    where: { riderId },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ ok: true, walletBalance: rider.walletBalance, totalDeliveries: rider.totalDeliveries, withdrawals });
});

// POST /api/riders/me/withdrawals  { amount }
const requestWithdrawal = asyncHandler(async (req, res) => {
  const riderId = req.user.riderProfile?.id;
  if (!riderId) {
    res.status(400);
    throw new Error('This account has no rider profile');
  }
  const amount = Number(req.body.amount);
  const rider = await prisma.riderProfile.findUnique({ where: { id: riderId } });
  if (!amount || amount <= 0 || amount > rider.walletBalance) {
    res.status(400);
    throw new Error('Invalid withdrawal amount');
  }
  const withdrawal = await prisma.withdrawalRequest.create({ data: { riderId, amount } });
  res.status(201).json({ ok: true, withdrawal });
});

// ── Admin rider management ────────────────────────────────

// GET /api/riders  — admin
const listRiders = asyncHandler(async (req, res) => {
  const riders = await prisma.riderProfile.findMany({
    include: { user: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ ok: true, riders: riders.map((r) => ({ ...r, user: publicUser(r.user) })) });
});

// POST /api/riders  — admin  { name, phone, password, bikeNumber, area }
const createRider = asyncHandler(async (req, res) => {
  const { name, phone, password, bikeNumber, area } = req.body;
  if (!name || !phone || !password) {
    res.status(400);
    throw new Error('name, phone and password are required');
  }
  const existing = await prisma.user.findUnique({ where: { phone } });
  if (existing) {
    res.status(409);
    throw new Error('A user with this phone number already exists');
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: {
      name,
      phone,
      passwordHash,
      role: 'RIDER',
      riderProfile: { create: { bikeNumber, area } },
    },
    include: { riderProfile: true },
  });
  res.status(201).json({ ok: true, rider: { ...user.riderProfile, user: publicUser(user) } });
});

// PATCH /api/riders/:id  — admin  { name, bikeNumber, area, isBlocked }
const updateRider = asyncHandler(async (req, res) => {
  const rider = await prisma.riderProfile.findUnique({ where: { id: req.params.id } });
  if (!rider) {
    res.status(404);
    throw new Error('Rider not found');
  }
  const { name, bikeNumber, area, isBlocked } = req.body;
  const [updatedUser, updatedRider] = await prisma.$transaction([
    prisma.user.update({
      where: { id: rider.userId },
      data: { ...(name !== undefined ? { name } : {}), ...(isBlocked !== undefined ? { isBlocked } : {}) },
    }),
    prisma.riderProfile.update({
      where: { id: rider.id },
      data: { ...(bikeNumber !== undefined ? { bikeNumber } : {}), ...(area !== undefined ? { area } : {}) },
    }),
  ]);
  res.json({ ok: true, rider: { ...updatedRider, user: publicUser(updatedUser) } });
});

// DELETE /api/riders/:id  — admin
const deleteRider = asyncHandler(async (req, res) => {
  const rider = await prisma.riderProfile.findUnique({ where: { id: req.params.id } });
  if (!rider) {
    res.status(404);
    throw new Error('Rider not found');
  }
  await prisma.user.delete({ where: { id: rider.userId } }); // cascades to riderProfile
  res.json({ ok: true });
});

module.exports = {
  myDashboard,
  setOnlineStatus,
  updateLocation,
  myEarnings,
  requestWithdrawal,
  listRiders,
  createRider,
  updateRider,
  deleteRider,
};
