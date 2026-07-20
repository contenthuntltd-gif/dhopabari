const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const prisma = new PrismaClient();

const CATEGORIES = [
  { name: 'Men', nameBn: 'পুরুষ', icon: 'male', sortOrder: 1 },
  { name: 'Women', nameBn: 'মহিলা', icon: 'female', sortOrder: 2 },
  { name: 'Kids', nameBn: 'শিশু', icon: 'kids', sortOrder: 3 },
  { name: 'Home', nameBn: 'ঘরের কাপড়', icon: 'home', sortOrder: 4 },
];

const SERVICES = [
  { name: 'Wash', nameBn: 'ওয়াশ', icon: 'wash', sortOrder: 1 },
  { name: 'Dry Clean', nameBn: 'ড্রাই ক্লিন', icon: 'dry-clean', sortOrder: 2 },
];

// [categoryName, itemName, itemNameBn, washPrice, dryCleanPrice]
const PRICE_ITEMS = [
  ['Men', 'Shirt', 'শার্ট', 30, 60],
  ['Men', 'Pant', 'প্যান্ট', 30, 60],
  ['Men', 'T-shirt', 'টি-শার্ট', 20, 50],
  ['Men', 'Panjabi', 'পাঞ্জাবি', 50, 80],
  ['Men', 'Jeans', 'জিন্স', 40, 70],
  ['Men', 'Coat', 'কোট', 150, 250],
  ['Men', 'Sweater', 'সুইটার', 60, 100],
  ['Women', 'Saree', 'শাড়ি', 80, 150],
  ['Women', 'Salwar Kameez', 'সালোয়ার কামিজ', 60, 100],
  ['Women', 'Borka', 'বোরকা', 50, 90],
  ['Women', 'Blouse', 'ব্লাউজ', 25, 40],
  ['Kids', 'Kids Shirt', 'বাচ্চাদের শার্ট', 20, 40],
  ['Kids', 'Kids Frock', 'বাচ্চাদের ফ্রক', 25, 45],
  ['Home', 'Bedsheet', 'বেডশিট', 40, 70],
  ['Home', 'Pillow Cover', 'বালিশ কভার', 20, 30],
  ['Home', 'Curtain', 'পর্দা', 100, 180],
  ['Home', 'Blanket', 'কম্বল', 150, 300],
];

// Cox's Bazar service areas offered at signup — stored as a Setting so
// admins can add/remove areas later without a schema change or app release.
const SERVICE_AREAS = [
  'কলাতলী', 'সুগন্ধা', 'লাবণী', 'ঝাউতলা', 'বার্মিজ মার্কেট',
  'পানবাজার রোড', 'হলিডে মোড়', 'পিটি স্কুল', 'খালুর দোকান', 'রাস্তামাথা',
  'টার্মিনাল', 'টেকপাড়া', 'পাহাড়তলী', 'ঘোনারপাড়া', 'সমিতিপাড়া',
];

async function main() {
  console.log('Seeding service areas...');
  await prisma.setting.upsert({
    where: { key: 'service_areas' },
    update: {},
    create: { key: 'service_areas', value: SERVICE_AREAS },
  });

  console.log('Seeding business hours...');
  await prisma.setting.upsert({
    where: { key: 'business_hours' },
    update: {},
    create: {
      key: 'business_hours',
      value: { openHour: 13, closeHour: 21, label: '১:০০ PM - ৯:০০ PM', everyDay: true },
    },
  });

  console.log('Seeding delivery options...');
  await prisma.setting.upsert({
    where: { key: 'delivery_options' },
    update: {},
    create: {
      key: 'delivery_options',
      value: [
        { type: 'FREE', label: 'ফ্রি ডেলিভারি', charge: 0, eta: '৩-৫ দিন', isDefault: true },
        { type: 'EXPRESS', label: 'এক্সপ্রেস ডেলিভারি', charge: 50, eta: '২ দিনের মধ্যে', isDefault: false },
      ],
    },
  });

  console.log('Seeding categories...');
  const categoryMap = {};
  for (const c of CATEGORIES) {
    const category = await prisma.category.upsert({ where: { name: c.name }, update: c, create: c });
    categoryMap[c.name] = category.id;
  }

  console.log('Seeding services...');
  const serviceMap = {};
  for (const s of SERVICES) {
    const service = await prisma.service.upsert({ where: { name: s.name }, update: s, create: s });
    serviceMap[s.name] = service.id;
  }

  console.log('Seeding price items...');
  for (const [categoryName, name, nameBn, washPrice, dryPrice] of PRICE_ITEMS) {
    await prisma.priceItem.upsert({
      where: {
        categoryId_serviceId_name: { categoryId: categoryMap[categoryName], serviceId: serviceMap['Wash'], name },
      },
      update: { price: washPrice, nameBn },
      create: { categoryId: categoryMap[categoryName], serviceId: serviceMap['Wash'], name, nameBn, price: washPrice },
    });
    await prisma.priceItem.upsert({
      where: {
        categoryId_serviceId_name: { categoryId: categoryMap[categoryName], serviceId: serviceMap['Dry Clean'], name },
      },
      update: { price: dryPrice, nameBn },
      create: { categoryId: categoryMap[categoryName], serviceId: serviceMap['Dry Clean'], name, nameBn, price: dryPrice },
    });
  }

  console.log('Seeding admin account...');
  const adminPhone = process.env.ADMIN_SEED_PHONE || '01700000000';
  const adminPassword = process.env.ADMIN_SEED_PASSWORD || 'admin2026';
  const passwordHash = await bcrypt.hash(adminPassword, 10);
  await prisma.user.upsert({
    where: { phone: adminPhone },
    update: {},
    create: { phone: adminPhone, name: 'Admin', role: 'ADMIN', passwordHash },
  });
  console.log(`Admin account ready — phone: ${adminPhone}, password: ${adminPassword} (change this in production!)`);

  console.log('Seeding welcome coupon...');
  await prisma.coupon.upsert({
    where: { code: 'FIRST10' },
    update: {},
    create: { code: 'FIRST10', type: 'PERCENT', value: 10, minOrderAmount: 0, maxDiscount: 100, usageLimit: null, isActive: true },
  });

  console.log('Seeding test rider account...');
  const riderPhone = '01711111111';
  const riderPassword = 'rider2026';
  const riderPasswordHash = await bcrypt.hash(riderPassword, 10);
  await prisma.user.upsert({
    where: { phone: riderPhone },
    update: {},
    create: {
      phone: riderPhone,
      name: 'Test Rider',
      role: 'RIDER',
      passwordHash: riderPasswordHash,
      riderProfile: { create: { bikeNumber: 'DHK-1234', area: 'Cox\'s Bazar Sadar', isOnline: true } },
    },
  });
  console.log(`Rider account ready — phone: ${riderPhone}, password: ${riderPassword}`);

  console.log('Seeding test customer account...');
  const customerPhone = '01722222222';
  const customerPassword = 'customer2026';
  const customerPasswordHash = await bcrypt.hash(customerPassword, 10);
  const customer = await prisma.user.upsert({
    where: { phone: customerPhone },
    update: {},
    create: { phone: customerPhone, name: 'Test Customer', role: 'CUSTOMER', passwordHash: customerPasswordHash },
  });
  await prisma.address.upsert({
    where: { id: 'seed_test_address' },
    update: {},
    create: {
      id: 'seed_test_address',
      userId: customer.id,
      label: 'Home',
      addressLine: 'House 12, Road 3, Kolatoli',
      area: "Cox's Bazar Sadar",
      isDefault: true,
    },
  });
  console.log(`Customer account ready — phone: ${customerPhone}, password: ${customerPassword}`);

  console.log('Seed complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
