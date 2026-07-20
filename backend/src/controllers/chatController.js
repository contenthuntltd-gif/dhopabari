const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');
const { notifyUser } = require('../services/notify');

async function assertChatAccess(chat, user) {
  if (user.role === 'ADMIN') return true;
  if (user.role === 'CUSTOMER' && chat.customerId === user.id) return true;
  if (user.role === 'RIDER' && chat.riderId === user.riderProfile?.id) return true;
  return false;
}

// GET /api/chats  — list chats the current user is part of
const listMyChats = asyncHandler(async (req, res) => {
  let where = {};
  if (req.user.role === 'CUSTOMER') where.customerId = req.user.id;
  else if (req.user.role === 'RIDER') where.riderId = req.user.riderProfile?.id || '__none__';
  // ADMIN sees all support chats
  else where.type = 'SUPPORT';

  const chats = await prisma.chat.findMany({
    where,
    include: {
      customer: true,
      rider: { include: { user: true } },
      order: true,
      messages: { orderBy: { createdAt: 'desc' }, take: 1 },
    },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ ok: true, chats });
});

// POST /api/chats  { type: 'SUPPORT'|'RIDER', orderId? }
const createChat = asyncHandler(async (req, res) => {
  const { type, orderId } = req.body;
  if (!['SUPPORT', 'RIDER'].includes(type)) {
    res.status(400);
    throw new Error('type must be SUPPORT or RIDER');
  }

  let riderId = null;
  let order = null;
  if (type === 'RIDER') {
    if (!orderId) {
      res.status(400);
      throw new Error('orderId is required to start a rider chat');
    }
    order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || !order.riderId) {
      res.status(400);
      throw new Error('Order has no assigned rider yet');
    }
    riderId = order.riderId;
  }

  // customerId is never taken from the request body verbatim — that would
  // let a RIDER impersonate an arbitrary customer. CUSTOMER callers can
  // only open a chat for themselves; RIDER callers get the customer of the
  // order they're chatting about; only ADMIN may open a chat on behalf of
  // an explicit customerId (e.g. from the support console).
  let customerId;
  if (req.user.role === 'CUSTOMER') {
    customerId = req.user.id;
  } else if (req.user.role === 'RIDER') {
    if (!order) {
      res.status(400);
      throw new Error('Riders can only start chats tied to one of their orders');
    }
    customerId = order.customerId;
  } else {
    customerId = req.body.customerId;
  }
  if (!customerId) {
    res.status(400);
    throw new Error('customerId is required');
  }

  const chat = await prisma.chat.create({
    data: {
      type,
      orderId: orderId || null,
      customerId,
      riderId,
    },
    include: { customer: true, rider: { include: { user: true } } },
  });
  res.status(201).json({ ok: true, chat });
});

// GET /api/chats/:id/messages
const listMessages = asyncHandler(async (req, res) => {
  const chat = await prisma.chat.findUnique({ where: { id: req.params.id } });
  if (!chat) {
    res.status(404);
    throw new Error('Chat not found');
  }
  if (!(await assertChatAccess(chat, req.user))) {
    res.status(403);
    throw new Error('You do not have access to this chat');
  }
  const messages = await prisma.message.findMany({
    where: { chatId: chat.id },
    include: { sender: true },
    orderBy: { createdAt: 'asc' },
  });
  res.json({ ok: true, messages });
});

// POST /api/chats/:id/messages  { text?, imageUrl?, fileUrl? }
const sendMessage = asyncHandler(async (req, res) => {
  const { text, imageUrl, fileUrl } = req.body;
  if (!text && !imageUrl && !fileUrl) {
    res.status(400);
    throw new Error('Message must have text, an image, or a file');
  }
  const chat = await prisma.chat.findUnique({
    where: { id: req.params.id },
    include: { customer: true, rider: { include: { user: true } } },
  });
  if (!chat) {
    res.status(404);
    throw new Error('Chat not found');
  }
  if (!(await assertChatAccess(chat, req.user))) {
    res.status(403);
    throw new Error('You do not have access to this chat');
  }

  const message = await prisma.message.create({
    data: { chatId: chat.id, senderId: req.user.id, text, imageUrl, fileUrl },
    include: { sender: true },
  });

  const recipientUserId =
    req.user.id === chat.customerId ? chat.rider?.userId : chat.customerId;
  const recipientToken =
    req.user.id === chat.customerId ? chat.rider?.user?.fcmToken : chat.customer?.fcmToken;
  if (recipientUserId) {
    await notifyUser({
      userId: recipientUserId,
      type: 'SYSTEM',
      title: 'New message',
      titleBn: 'নতুন বার্তা',
      body: text || 'Sent an attachment',
      bodyBn: text || 'একটি ফাইল পাঠিয়েছে',
      data: { chatId: chat.id },
      fcmToken: recipientToken,
    }).catch(() => {});
  }

  res.status(201).json({ ok: true, message });
});

module.exports = { listMyChats, createChat, listMessages, sendMessage };
