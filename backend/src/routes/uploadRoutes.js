const express = require('express');
const multer = require('multer');
const ctrl = require('../controllers/uploadController');
const { authenticate } = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });

const router = express.Router();

router.post('/', authenticate, upload.single('file'), ctrl.uploadImage);

module.exports = router;
