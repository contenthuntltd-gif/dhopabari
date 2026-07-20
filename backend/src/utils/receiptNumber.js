/**
 * Generates the next sequential memo number for the given year inside an
 * existing Prisma transaction — e.g. "DB-MEMO-2026-000123". Gap-free and
 * collision-free: the increment happens atomically as part of the same
 * transaction that inserts the Receipt row, so two concurrent requests
 * can never be handed the same number.
 */
async function nextReceiptNumber(tx, year = new Date().getFullYear()) {
  const counter = await tx.receiptCounter.upsert({
    where: { year },
    create: { year, lastNumber: 1 },
    update: { lastNumber: { increment: 1 } },
  });
  return `DB-MEMO-${year}-${String(counter.lastNumber).padStart(6, '0')}`;
}

module.exports = { nextReceiptNumber };
