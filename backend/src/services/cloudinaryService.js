const env = require('../config/env');

function getClient() {
  if (!env.cloudinary.configured) return null;
  const cloudinary = require('cloudinary').v2;
  cloudinary.config({
    cloud_name: env.cloudinary.cloudName,
    api_key: env.cloudinary.apiKey,
    api_secret: env.cloudinary.apiSecret,
  });
  return cloudinary;
}

/**
 * Uploads a buffer (from multer memory storage) to Cloudinary.
 * Throws a 503 error if Cloudinary isn't configured.
 */
async function uploadBuffer(buffer, folder = 'dhopa-bari') {
  const cloudinary = getClient();
  if (!cloudinary) {
    const err = new Error('Image uploads are not configured on this server (missing Cloudinary credentials)');
    err.status = 503;
    throw err;
  }
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream({ folder }, (error, result) => {
      if (error) return reject(error);
      resolve(result);
    });
    stream.end(buffer);
  });
}

module.exports = { uploadBuffer, isConfigured: () => env.cloudinary.configured };
