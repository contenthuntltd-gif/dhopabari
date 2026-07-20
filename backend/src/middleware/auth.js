const asyncHandler = require('express-async-handler');
const { verifyAppToken } = require('../utils/jwt');
const prisma = require('../config/prisma');

/**
 * Requires a valid app JWT (issued by /api/auth/*) in the Authorization
 * header as `Bearer <token>`. Attaches req.user (the full User row, with
 * riderProfile included for riders).
 */
const authenticate = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    res.status(401);
    throw new Error('Authentication token missing');
  }

  let decoded;
  try {
    decoded = verifyAppToken(token);
  } catch (e) {
    res.status(401);
    throw new Error('Invalid or expired token');
  }

  const user = await prisma.user.findUnique({
    where: { id: decoded.sub },
    include: { riderProfile: true },
  });
  if (!user) {
    res.status(401);
    throw new Error('User no longer exists');
  }
  if (user.isBlocked) {
    res.status(403);
    throw new Error('This account has been blocked');
  }

  req.user = user;
  next();
});

/**
 * Restricts a route to one or more roles. Use after `authenticate`.
 *   router.get('/admin/stuff', authenticate, authorize('ADMIN'), handler)
 */
function authorize(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      res.status(403);
      return next(new Error('You do not have permission to access this resource'));
    }
    next();
  };
}

module.exports = { authenticate, authorize };
