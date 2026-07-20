const express = require('express');
const ctrl = require('../controllers/authController');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimit');
const {
  registerSchema,
  loginSchema,
  adminLoginSchema,
  forgotPasswordRequestSchema,
  forgotPasswordResetSchema,
  firebaseLoginSchema,
} = require('../utils/validators');

const router = express.Router();

router.post('/register', authLimiter, validate(registerSchema), ctrl.register);
router.post('/login', authLimiter, validate(loginSchema), ctrl.login);
router.post('/firebase-login', authLimiter, validate(firebaseLoginSchema), ctrl.firebaseLogin);
router.post('/admin-login', authLimiter, validate(adminLoginSchema), ctrl.adminLogin);
router.post('/rider-login', authLimiter, validate(adminLoginSchema), ctrl.riderLogin);
router.post('/forgot-password/request', authLimiter, validate(forgotPasswordRequestSchema), ctrl.forgotPasswordRequest);
router.post('/forgot-password/reset', authLimiter, validate(forgotPasswordResetSchema), ctrl.forgotPasswordReset);
router.get('/me', authenticate, ctrl.me);

module.exports = router;
