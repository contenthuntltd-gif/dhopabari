function notFound(req, res, next) {
  res.status(404);
  next(new Error(`Route not found: ${req.method} ${req.originalUrl}`));
}

const isDev = process.env.NODE_ENV === 'development';

// Prisma (and other infra-layer) errors carry internal file paths and raw
// query traces in `message` — safe to log, never safe to send to a client,
// in dev OR production. Full details always go to the server console via
// console.error() below; only a clean, user-facing message is ever sent
// in the response body.
function isInternalError(err) {
  return Boolean(err.constructor?.name?.startsWith('Prisma') || err.code?.startsWith?.('P'));
}

// A Prisma error whose message mentions authentication/connection almost
// always means the database itself is unreachable or misconfigured, not
// that anything is wrong with the request — worth a distinct message so
// it doesn't read like a generic crash.
function isDatabaseUnavailable(err) {
  if (!isInternalError(err)) return false;
  const msg = String(err.message || '');
  return /Authentication failed|Can't reach database|connect ECONNREFUSED|database server/i.test(msg);
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  const status = err.status || (res.statusCode && res.statusCode !== 200 ? res.statusCode : 500);
  if (process.env.NODE_ENV !== 'test') {
    console.error(err);
  }
  const internal = isInternalError(err);
  let message;
  if (isDatabaseUnavailable(err)) {
    message = 'Database is not reachable right now. Please try again shortly.';
  } else if (internal) {
    message = 'Internal server error';
  } else {
    message = err.message || 'Internal server error';
  }
  res.status(status).json({
    ok: false,
    error: message,
    ...(isDev && !internal ? { stack: err.stack } : {}),
  });
}

module.exports = { notFound, errorHandler };
