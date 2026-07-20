const jwt = require('jsonwebtoken');
const env = require('../config/env');

function signAppToken(payload) {
  return jwt.sign(payload, env.jwtSecret, { expiresIn: env.jwtExpiresIn });
}

function verifyAppToken(token) {
  return jwt.verify(token, env.jwtSecret);
}

module.exports = { signAppToken, verifyAppToken };
