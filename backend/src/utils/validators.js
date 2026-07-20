const { z } = require('zod');

const phoneSchema = z
  .string()
  .trim()
  .regex(/^01[3-9]\d{8}$/, 'Enter a valid 11-digit Bangladeshi mobile number (e.g. 01712345678)');

const registerSchema = z.object({
  name: z.string().trim().min(1, 'Full name is required'),
  phone: phoneSchema,
  password: z.string().min(6, 'Password must be at least 6 characters'),
  // Not enum-validated against a fixed list — the service area list is
  // editable from the Admin Panel (see Setting["service_areas"]), so the
  // API only checks that something was actually selected.
  area: z.string().trim().min(1, 'Area is required'),
  localAddress: z.string().trim().min(1, 'House/Building/Flat/Road is required'),
  whatsappNumber: z.string().trim().regex(/^01[3-9]\d{8}$/, 'Enter a valid 11-digit WhatsApp number (e.g. 01712345678)').optional().or(z.literal('')),
});

const loginSchema = z.object({
  phone: phoneSchema,
  password: z.string().min(1),
});

const adminLoginSchema = z.object({
  phone: phoneSchema,
  password: z.string().min(1),
});

// Customer-facing password reset never uses SMS/phone OTP. Google-linked
// accounts manage their password with Google directly; Mobile Number +
// Password accounts reset via a one-time link emailed to the address on
// file (see emailService.js). No email on file -> no automated reset link,
// the client is expected to direct the user to support instead.
const forgotPasswordRequestSchema = z.object({
  phone: phoneSchema,
});

const forgotPasswordResetSchema = z.object({
  token: z.string().min(1, 'Reset token is required'),
  newPassword: z.string().min(6, 'Password must be at least 6 characters'),
});

const firebaseLoginSchema = z.object({
  idToken: z.string().min(1),
});

module.exports = {
  phoneSchema,
  registerSchema,
  loginSchema,
  adminLoginSchema,
  forgotPasswordRequestSchema,
  forgotPasswordResetSchema,
  firebaseLoginSchema,
};
