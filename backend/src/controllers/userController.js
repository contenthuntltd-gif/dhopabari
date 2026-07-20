const asyncHandler = require('express-async-handler');
const prisma = require('../config/prisma');

function publicUser(user) {
  const { passwordHash, ...safe } = user;
  return safe;
}

// PATCH /api/users/me  { name, email, avatarUrl }
const updateMe = asyncHandler(async (req, res) => {
  const { name, email, avatarUrl } = req.body;
  const user = await prisma.user.update({
    where: { id: req.user.id },
    data: {
      ...(name !== undefined ? { name } : {}),
      ...(email !== undefined ? { email } : {}),
      ...(avatarUrl !== undefined ? { avatarUrl } : {}),
    },
  });
  res.json({ ok: true, user: publicUser(user) });
});

// GET /api/users/me/addresses
const listAddresses = asyncHandler(async (req, res) => {
  const addresses = await prisma.address.findMany({
    where: { userId: req.user.id },
    orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
  });
  res.json({ ok: true, addresses });
});

// POST /api/users/me/addresses  { label, addressLine, area, lat, lng, isDefault }
const createAddress = asyncHandler(async (req, res) => {
  const { label, addressLine, area, lat, lng, isDefault } = req.body;
  if (!addressLine || !area) {
    res.status(400);
    throw new Error('addressLine and area are required');
  }
  const address = await prisma.$transaction(async (tx) => {
    if (isDefault) {
      await tx.address.updateMany({ where: { userId: req.user.id }, data: { isDefault: false } });
    }
    return tx.address.create({
      data: { userId: req.user.id, label, addressLine, area, lat, lng, isDefault: Boolean(isDefault) },
    });
  });
  res.status(201).json({ ok: true, address });
});

// DELETE /api/users/me/addresses/:id
const deleteAddress = asyncHandler(async (req, res) => {
  const address = await prisma.address.findUnique({ where: { id: req.params.id } });
  if (!address || address.userId !== req.user.id) {
    res.status(404);
    throw new Error('Address not found');
  }
  await prisma.address.delete({ where: { id: address.id } });
  res.json({ ok: true });
});

module.exports = { updateMe, listAddresses, createAddress, deleteAddress };
