/**
 * Dhopa Bari office/shop hours — 1:00 PM to 9:00 PM, every day. Orders are
 * always accepted regardless of the time (see orderController.createOrder);
 * this only decides whether to flag the order as placed off-hours so the
 * client can show the "our team will confirm when we open" message instead
 * of silently pretending someone is looking at it right now.
 */
const OPEN_HOUR = 13; // 1:00 PM (24h)
const CLOSE_HOUR = 21; // 9:00 PM (24h)

const OFF_HOURS_MESSAGE_BN =
  'আপনার অর্ডার গ্রহণ করা হয়েছে। অফিস খোলার সময় (১:০০ PM - ৯:০০ PM) আমাদের টিম এটি নিশ্চিত করবে।';

function isOpenNow(date = new Date()) {
  const hour = date.getHours();
  return hour >= OPEN_HOUR && hour < CLOSE_HOUR;
}

module.exports = { OPEN_HOUR, CLOSE_HOUR, OFF_HOURS_MESSAGE_BN, isOpenNow };
