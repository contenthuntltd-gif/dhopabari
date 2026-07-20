const prisma = require('../config/prisma');
const firebaseAdmin = require('./firebaseAdmin');

// FINAL master order status flow — six statuses, used everywhere
// (notifications, push, WhatsApp/SMS/email templates once wired up).
const STATUS_LABELS = {
  CONFIRMED: { en: 'Order Confirmed', bn: 'অর্ডার নিশ্চিত হয়েছে', emoji: '✅' },
  PICKED_UP: { en: 'Clothes Picked Up', bn: 'কাপড় সংগ্রহ করা হয়েছে', emoji: '🚚' },
  CLEANING: { en: 'Cleaning in Progress', bn: 'কাপড় পরিষ্কার করা হচ্ছে', emoji: '🧺' },
  PACKAGING_DONE: { en: 'Packaging Completed', bn: 'প্যাকেজিং সম্পন্ন', emoji: '📦' },
  OUT_FOR_DELIVERY: { en: 'Out for Delivery', bn: 'ডেলিভারির পথে', emoji: '🚛' },
  DELIVERED: { en: 'Delivered', bn: 'ডেলিভারি সম্পন্ন', emoji: '🏠' },
  CANCELLED: { en: 'Order Cancelled', bn: 'অর্ডার বাতিল হয়েছে', emoji: '❌' },
};

/**
 * Creates an in-app Notification row for a user and (best-effort) sends a
 * push via FCM if the user has a registered device token. Push failures are
 * logged, not thrown — an undelivered push should never fail the request
 * that triggered it (e.g. an order status update).
 */
async function notifyUser({ userId, type, title, titleBn, body, bodyBn, data, fcmToken }) {
  const notification = await prisma.notification.create({
    data: { userId, type, title, titleBn, body, bodyBn, data },
  });
  if (fcmToken) {
    try {
      await firebaseAdmin.sendPushNotification({ token: fcmToken, title: titleBn || title, body: bodyBn || body, data });
    } catch (e) {
      console.warn('Push notification failed:', e.message);
    }
  }
  return notification;
}

async function notifyOrderStatusChange(order, customerFcmToken) {
  const label = STATUS_LABELS[order.status] || { en: order.status, bn: order.status };
  return notifyUser({
    userId: order.customerId,
    type: 'ORDER_UPDATE',
    title: `Order ${order.orderNumber}: ${label.en}`,
    titleBn: `অর্ডার ${order.orderNumber}: ${label.bn}`,
    body: `Your order status is now "${label.en}"`,
    bodyBn: `আপনার অর্ডারের অবস্থা এখন "${label.bn}"`,
    data: { orderId: order.id, status: order.status },
    fcmToken: customerFcmToken,
  });
}

module.exports = { notifyUser, notifyOrderStatusChange, STATUS_LABELS };
