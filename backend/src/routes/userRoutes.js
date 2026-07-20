const express = require('express');
const ctrl = require('../controllers/userController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);
router.patch('/me', ctrl.updateMe);
router.get('/me/addresses', ctrl.listAddresses);
router.post('/me/addresses', ctrl.createAddress);
router.delete('/me/addresses/:id', ctrl.deleteAddress);

module.exports = router;
