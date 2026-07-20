const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');
const { notifyUser } = require('../services/notify');

// GET /api/notifications  (mine + broadcast)
const listMine = asyncHandler(async (req, res) => {
  const notifications = await prisma.notification.findMany({
    where: { OR: [{ userId: req.user.id }, { userId: null }] },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  res.json({ ok: true, notifications });
});

// PATCH /api/notifications/:id/read
const markRead = asyncHandler(async (req, res) => {
  const notification = await prisma.notification.findUnique({ where: { id: req.params.id } });
  if (!notification || (notification.userId && notification.userId !== req.user.id)) {
    res.status(404);
    throw new Error('Notification not found');
  }
  const updated = await prisma.notification.update({ where: { id: notification.id }, data: { isRead: true } });
  res.json({ ok: true, notification: updated });
});

// PUT /api/notifications/device-token  { fcmToken }
const registerDeviceToken = asyncHandler(async (req, res) => {
  const { fcmToken } = req.body;
  await prisma.user.update({ where: { id: req.user.id }, data: { fcmToken } });
  res.json({ ok: true });
});

// POST /api/notifications/broadcast  — admin  { title, titleBn, body, bodyBn, type }
const broadcast = asyncHandler(async (req, res) => {
  const { title, titleBn, body, bodyBn, type } = req.body;
  if (!title || !body) {
    res.status(400);
    throw new Error('title and body are required');
  }
  const notification = await notifyUser({
    userId: null,
    type: type || 'OFFER',
    title,
    titleBn,
    body,
    bodyBn,
  });
  res.status(201).json({ ok: true, notification });
});

module.exports = { listMine, markRead, registerDeviceToken, broadcast };
