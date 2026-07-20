const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');

// GET /api/admin/dashboard
const dashboard = asyncHandler(async (req, res) => {
  const [total, pending, processing, delivered, cancelled, revenueAgg, latestOrders] = await Promise.all([
    prisma.order.count(),
    prisma.order.count({ where: { status: 'CONFIRMED' } }),
    prisma.order.count({
      where: { status: { in: ['PICKED_UP', 'CLEANING', 'PACKAGING_DONE', 'OUT_FOR_DELIVERY'] } },
    }),
    prisma.order.count({ where: { status: 'DELIVERED' } }),
    prisma.order.count({ where: { status: 'CANCELLED' } }),
    prisma.order.aggregate({ where: { status: 'DELIVERED' }, _sum: { total: true } }),
    prisma.order.findMany({
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: { customer: true, service: true, rider: { include: { user: true } } },
    }),
  ]);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayOrders = await prisma.order.count({ where: { createdAt: { gte: today } } });

  res.json({
    ok: true,
    stats: {
      totalOrders: total,
      todayOrders,
      pending,
      processing,
      delivered,
      cancelled,
      revenue: revenueAgg._sum.total || 0,
    },
    latestOrders,
  });
});

// GET /api/admin/reports?period=daily|weekly|monthly
const reports = asyncHandler(async (req, res) => {
  const period = req.query.period === 'weekly' ? 7 : req.query.period === 'monthly' ? 30 : 1;
  const since = new Date();
  since.setDate(since.getDate() - period);

  const orders = await prisma.order.findMany({
    where: { createdAt: { gte: since } },
    select: { createdAt: true, total: true, status: true },
  });

  const byDay = {};
  for (const o of orders) {
    const day = o.createdAt.toISOString().slice(0, 10);
    if (!byDay[day]) byDay[day] = { day, orders: 0, revenue: 0 };
    byDay[day].orders += 1;
    if (o.status === 'DELIVERED') byDay[day].revenue += o.total;
  }

  res.json({
    ok: true,
    period: req.query.period || 'daily',
    totalOrders: orders.length,
    totalRevenue: orders.filter((o) => o.status === 'DELIVERED').reduce((s, o) => s + o.total, 0),
    series: Object.values(byDay).sort((a, b) => a.day.localeCompare(b.day)),
  });
});

// GET /api/admin/customers?search=
const listCustomers = asyncHandler(async (req, res) => {
  const { search } = req.query;
  const where = {
    role: 'CUSTOMER',
    ...(search
      ? { OR: [{ name: { contains: search, mode: 'insensitive' } }, { phone: { contains: search, mode: 'insensitive' } }] }
      : {}),
  };
  const customers = await prisma.user.findMany({
    where,
    include: { _count: { select: { ordersAsCustomer: true } }, addresses: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json({
    ok: true,
    customers: customers.map(({ passwordHash, ...c }) => ({ ...c, orderCount: c._count.ordersAsCustomer })),
  });
});

// PATCH /api/admin/customers/:id/block  { isBlocked }
const setCustomerBlocked = asyncHandler(async (req, res) => {
  const user = await prisma.user.update({
    where: { id: req.params.id },
    data: { isBlocked: Boolean(req.body.isBlocked) },
  });
  const { passwordHash, ...safe } = user;
  res.json({ ok: true, customer: safe });
});

// GET /api/admin/settings
const getSettings = asyncHandler(async (req, res) => {
  const rows = await prisma.setting.findMany();
  const settings = Object.fromEntries(rows.map((r) => [r.key, r.value]));
  res.json({ ok: true, settings });
});

// PUT /api/admin/settings/:key  { value }
const putSetting = asyncHandler(async (req, res) => {
  const setting = await prisma.setting.upsert({
    where: { key: req.params.key },
    update: { value: req.body.value },
    create: { key: req.params.key, value: req.body.value },
  });
  res.json({ ok: true, setting });
});

module.exports = { dashboard, reports, listCustomers, setCustomerBlocked, getSettings, putSetting };
