const express = require('express');
const ctrl = require('../controllers/catalogController');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', ctrl.getCatalog); // public — customer app needs this before login too

router.post('/price-items', authenticate, authorize('ADMIN'), ctrl.createOrUpdatePriceItem);
router.delete('/price-items/:id', authenticate, authorize('ADMIN'), ctrl.deletePriceItem);
router.post('/categories', authenticate, authorize('ADMIN'), ctrl.createCategory);
router.post('/services', authenticate, authorize('ADMIN'), ctrl.createService);

module.exports = router;
