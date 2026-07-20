const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');

// GET /api/catalog  -> services, categories, and price items in one payload
// (this is what the customer app's New Order flow loads on step 1-3)
const getCatalog = asyncHandler(async (req, res) => {
  const [services, categories, priceItems] = await Promise.all([
    prisma.service.findMany({ where: { isActive: true }, orderBy: { sortOrder: 'asc' } }),
    prisma.category.findMany({ where: { isActive: true }, orderBy: { sortOrder: 'asc' } }),
    prisma.priceItem.findMany({ where: { isActive: true } }),
  ]);
  res.json({ ok: true, services, categories, priceItems });
});

// ── Admin pricing management ──────────────────────────────

// POST /api/catalog/price-items  { categoryId, serviceId, name, nameBn, price }
const createOrUpdatePriceItem = asyncHandler(async (req, res) => {
  const { id, categoryId, serviceId, name, nameBn, price } = req.body;
  if (!categoryId || !serviceId || !name || price === undefined) {
    res.status(400);
    throw new Error('categoryId, serviceId, name and price are required');
  }
  const priceItem = id
    ? await prisma.priceItem.update({ where: { id }, data: { categoryId, serviceId, name, nameBn, price } })
    : await prisma.priceItem.create({ data: { categoryId, serviceId, name, nameBn: nameBn || name, price } });
  res.json({ ok: true, priceItem });
});

// DELETE /api/catalog/price-items/:id
const deletePriceItem = asyncHandler(async (req, res) => {
  await prisma.priceItem.update({ where: { id: req.params.id }, data: { isActive: false } });
  res.json({ ok: true });
});

// POST /api/catalog/categories  { name, nameBn, icon, sortOrder }
const createCategory = asyncHandler(async (req, res) => {
  const category = await prisma.category.create({ data: req.body });
  res.status(201).json({ ok: true, category });
});

// POST /api/catalog/services  { name, nameBn, icon, sortOrder }
const createService = asyncHandler(async (req, res) => {
  const service = await prisma.service.create({ data: req.body });
  res.status(201).json({ ok: true, service });
});

module.exports = { getCatalog, createOrUpdatePriceItem, deletePriceItem, createCategory, createService };
