const express = require('express');
const ctrl = require('../controllers/chatController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/', ctrl.listMyChats);
router.post('/', ctrl.createChat);
router.get('/:id/messages', ctrl.listMessages);
router.post('/:id/messages', ctrl.sendMessage);

module.exports = router;
