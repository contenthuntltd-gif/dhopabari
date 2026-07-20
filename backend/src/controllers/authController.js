const crypto = require('crypto');
const asyncHandler = require('express-async-handler');
const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');
const { signAppToken } = require('../utils/jwt');
const firebaseAdmin = require('../services/firebaseAdmin');
const { sendPasswordResetEmail } = require('../services/emailService');
const env = require('../config/env');

function publicUser(user) {
  const { passwordHash, resetPasswordTokenHash, resetPasswordExpiresAt, ...safe } = user;
  return safe;
}

// POST /api/auth/register  { name, phone, password, area, localAddress, whatsappNumber? }
const register = asyncHandler(async (req, res) => {
  const { phone, password, name, area, localAddress, whatsappNumber } = req.body;
  const existing = await prisma.user.findUnique({ where: { phone } });
  if (existing) {
    res.status(409);
    throw new Error('An account with this phone number already exists — please log in instead');
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.$transaction(async (tx) => {
    const created = await tx.user.create({
      data: { phone, name, passwordHash, role: 'CUSTOMER', whatsappNumber: whatsappNumber || null },
    });
    await tx.address.create({
      data: {
        userId: created.id,
        label: 'Home',
        addressLine: localAddress,
        area,
        isDefault: true,
      },
    });
    return created;
  });
  const token = signAppToken({ sub: user.id, role: user.role });
  res.status(201).json({ ok: true, token, user: publicUser(user) });
});

// POST /api/auth/login  { phone, password }
const login = asyncHandler(async (req, res) => {
  const { phone, password } = req.body;
  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user || user.role !== 'CUSTOMER' || !user.passwordHash) {
    res.status(401);
    throw new Error('No customer account found for this number — please create an account');
  }
  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    res.status(401);
    throw new Error('Incorrect password');
  }
  if (user.isBlocked) {
    res.status(403);
    throw new Error('This account has been blocked. Contact support.');
  }
  const token = signAppToken({ sub: user.id, role: user.role });
  res.json({ ok: true, token, user: publicUser(user) });
});

// POST /api/auth/firebase-login  { idToken }
// Used for "Continue with Google" from the client apps (Firebase Authentication).
// Creates the customer account on first sign-in, logs in on subsequent ones.
const firebaseLogin = asyncHandler(async (req, res) => {
  const { idToken } = req.body;
  const decoded = await firebaseAdmin.verifyIdToken(idToken);

  let user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });
  if (!user && decoded.phone) {
    user = await prisma.user.findUnique({ where: { phone: decoded.phone } });
    if (user) user = await prisma.user.update({ where: { id: user.id }, data: { firebaseUid: decoded.uid } });
  }
  if (!user) {
    user = await prisma.user.create({
      data: {
        firebaseUid: decoded.uid,
        phone: decoded.phone || `pending_${decoded.uid}`,
        email: decoded.email,
        name: decoded.name,
        role: 'CUSTOMER',
      },
    });
  }
  if (user.isBlocked) {
    res.status(403);
    throw new Error('This account has been blocked. Contact support.');
  }
  const token = signAppToken({ sub: user.id, role: user.role });
  res.json({ ok: true, token, user: publicUser(user), devMode: decoded.devMode || false });
});

// POST /api/auth/admin-login  { phone, password }
const adminLogin = asyncHandler(async (req, res) => {
  const { phone, password } = req.body;
  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user || user.role !== 'ADMIN' || !user.passwordHash) {
    res.status(401);
    throw new Error('Invalid admin credentials');
  }
  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    res.status(401);
    throw new Error('Invalid admin credentials');
  }
  const token = signAppToken({ sub: user.id, role: user.role });
  res.json({ ok: true, token, user: publicUser(user) });
});

// POST /api/auth/rider-login  { phone, password }
const riderLogin = asyncHandler(async (req, res) => {
  const { phone, password } = req.body;
  const user = await prisma.user.findUnique({ where: { phone }, include: { riderProfile: true } });
  if (!user || user.role !== 'RIDER' || !user.passwordHash) {
    res.status(401);
    throw new Error('Invalid rider credentials');
  }
  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    res.status(401);
    throw new Error('Invalid rider credentials');
  }
  const token = signAppToken({ sub: user.id, role: user.role });
  res.json({ ok: true, token, user: publicUser(user) });
});

// POST /api/auth/forgot-password/request  { phone }
// No SMS/phone OTP anywhere in this flow. If the account has an email on
// file, a one-time reset link is emailed to it (dev mode without SMTP
// configured logs the link server-side and returns it in the response so
// the flow stays testable). If there is no email on file, there is no
// automated channel to deliver a reset link to — the client should direct
// the user to contact support instead.
const forgotPasswordRequest = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user) {
    res.status(404);
    throw new Error('No account found for this number');
  }
  if (!user.email) {
    return res.json({ ok: true, emailOnFile: false, message: 'No email on file for this account — please contact support to reset your password.' });
  }

  const rawToken = crypto.randomBytes(32).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const expiresAt = new Date(Date.now() + env.resetPassword.tokenTtlMinutes * 60 * 1000);
  await prisma.user.update({ where: { id: user.id }, data: { resetPasswordTokenHash: tokenHash, resetPasswordExpiresAt: expiresAt } });

  const resetUrl = `${env.resetPassword.webUrl}?token=${rawToken}`;
  const result = await sendPasswordResetEmail({ to: user.email, name: user.name, resetUrl });

  res.json({
    ok: true,
    emailOnFile: true,
    message: 'A password reset link has been sent to the email on file.',
    // Only present when SMTP isn't configured (dev/testing convenience) — never sent in production.
    ...(result.sent ? {} : { devResetToken: rawToken }),
  });
});

// POST /api/auth/forgot-password/reset  { token, newPassword }
const forgotPasswordReset = asyncHandler(async (req, res) => {
  const { token, newPassword } = req.body;
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const user = await prisma.user.findFirst({ where: { resetPasswordTokenHash: tokenHash } });
  if (!user || !user.resetPasswordExpiresAt || user.resetPasswordExpiresAt < new Date()) {
    res.status(400);
    throw new Error('This reset link is invalid or has expired — please request a new one');
  }
  const passwordHash = await bcrypt.hash(newPassword, 10);
  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash, resetPasswordTokenHash: null, resetPasswordExpiresAt: null },
  });
  res.json({ ok: true });
});

// GET /api/auth/me
const me = asyncHandler(async (req, res) => {
  res.json({ ok: true, user: publicUser(req.user) });
});

module.exports = {
  register,
  login,
  firebaseLogin,
  adminLogin,
  riderLogin,
  forgotPasswordRequest,
  forgotPasswordReset,
  me,
};
