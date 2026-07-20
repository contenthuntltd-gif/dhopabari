function generateOrderNumber() {
  const rand = Math.floor(100000 + Math.random() * 900000);
  return `DB${rand}`;
}

module.exports = { generateOrderNumber };
