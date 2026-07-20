const asyncHandler = require('express-async-handler');
const cloudinaryService = require('../services/cloudinaryService');

// POST /api/uploads  (multipart/form-data, field name "file")
const uploadImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    res.status(400);
    throw new Error('No file uploaded (expected multipart field "file")');
  }
  const result = await cloudinaryService.uploadBuffer(req.file.buffer, 'dhopa-bari');
  res.status(201).json({ ok: true, url: result.secure_url, publicId: result.public_id });
});

module.exports = { uploadImage };
