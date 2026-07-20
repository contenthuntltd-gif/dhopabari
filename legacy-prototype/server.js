const http = require("http");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

const PORT = Number(process.env.PORT || 4177);
const ROOT = __dirname;
const DATA_DIR = path.join(ROOT, "data");
const DB_FILE = path.join(DATA_DIR, "db.json");

function normalizePhone(p) {
  if (!p) return "";
  const bnToEn = {
    "০": "0", "১": "1", "২": "2", "৩": "3", "৪": "4",
    "৫": "5", "৬": "6", "৭": "7", "৮": "8", "৯": "9"
  };
  let clean = String(p).trim().split("").map(c => bnToEn[c] || c).join("");
  clean = clean.replace(/\D/g, "");
  if (clean.startsWith("880")) clean = clean.substring(2);
  else if (clean.startsWith("88")) clean = clean.substring(2);
  if (clean.length === 10 && clean.startsWith("1")) {
    clean = "0" + clean;
  }
  return clean;
}

const defaultDb = {
  prices: [
    { id: "shirt", category: "male", name: "শার্ট", wash: 40, dry: 60, combo: 50, iron: 8 },
    { id: "pant", category: "male", name: "প্যান্ট", wash: 40, dry: 60, combo: 50, iron: 8 },
    { id: "tshirt", category: "male", name: "টি-শার্ট", wash: 40, dry: 60, combo: 50, iron: 8 },
    { id: "panjabi", category: "male", name: "পাঞ্জাবি", wash: 50, dry: 70, combo: 60, iron: 10 },
    { id: "jubbah", category: "male", name: "জুব্বা", wash: 60, dry: 80, combo: 70, iron: 12 },
    { id: "pajama", category: "male", name: "পায়জামা", wash: 40, dry: 60, combo: 50, iron: 8 },
    { id: "coat", category: "male", name: "কোট", wash: 200, dry: 200, combo: 210, iron: 20 },
    { id: "kuti", category: "male", name: "কটি", wash: 120, dry: 120, combo: 130, iron: 15 },
    { id: "sweater", category: "male", name: "সুইটার", wash: 100, dry: 200, combo: 110, iron: 20 },
    { id: "jacket", category: "male", name: "জ্যাকেট", wash: 100, dry: 200, combo: 110, iron: 20 },
    { id: "shal", category: "male", name: "শাল", wash: 100, dry: 200, combo: 110, iron: 20 },
    { id: "sherwani", category: "male", name: "শেরওয়ানি", wash: 250, dry: 250, combo: 260, iron: 25 },
    { id: "suit", category: "male", name: "স্যুট", wash: 250, dry: 350, combo: 270, iron: 25 },
    { id: "tie", category: "male", name: "টাই", wash: 40, dry: 40, combo: 45, iron: 8 },
    { id: "borka", category: "female", name: "বোরকা", wash: 80, dry: 120, combo: 95, iron: 15 },
    { id: "saree", category: "female", name: "শাড়ি", wash: 150, dry: 400, combo: 180, iron: 30 },
    { id: "salwar", category: "female", name: "সালোয়ার, কামিজ, ওড়না", wash: 120, dry: 180, combo: 140, iron: 25 },
    { id: "blouse", category: "female", name: "ব্লাউজ", wash: 40, dry: 60, combo: 50, iron: 8 },
    { id: "lehenga", category: "female", name: "লেহেঙ্গা / গাউন", wash: 300, dry: 800, combo: 350, iron: 40 },
    { id: "hijab", category: "female", name: "হিজাব", wash: 40, dry: 60, combo: 50, iron: 8 },
    { id: "bedsheet", category: "home", name: "বেডশিট / চাদর", wash: 60, dry: 60, combo: 70, iron: 15 },
    { id: "pillow", category: "home", name: "বালিশ কভার", wash: 30, dry: 30, combo: 35, iron: 8 },
    { id: "towel", category: "home", name: "টাওয়েল", wash: 80, dry: 80, combo: 85, iron: 8 },
    { id: "curtain", category: "home", name: "পর্দা", wash: 150, dry: 250, combo: 180, iron: 20 },
    { id: "blanket", category: "home", name: "কম্বল", wash: 300, dry: 800, combo: 350, iron: 30 },
    { id: "comforter", category: "home", name: "কমফোর্টার", wash: 200, dry: 650, combo: 250, iron: 30 },
    { id: "nokshi", category: "home", name: "নকশী কাঁথা", wash: 60, dry: 80, combo: 70, iron: 10 },
    { id: "jainamaz", category: "home", name: "জায়নামাজ", wash: 0, dry: 0, combo: 0, iron: 0 }
  ],
  customers: [
    { id: "cus_rahim", name: "রহিম উদ্দিন", phone: "০১৭XXXXXXXX", password: "123456", address: "বাসা ১২, রোড ৩, কলাতলী", orders: 12 },
    { id: "cus_sumi", name: "সুমি আক্তার", phone: "০১৮XXXXXXXX", password: "123456", address: "সুগন্ধা, কক্সবাজার", orders: 8 }
  ],
  riders: [
    { id: "rider_karim", name: "করিম ভাই", phone: "01912345678", username: "karim", password: "123", online: true, tasks: 4 },
    { id: "rider_mamun", name: "মামুন ভাই", phone: "01612345678", username: "mamun", password: "123", online: true, tasks: 2 },
    { id: "rider_shahin", name: "শাহিন ভাই", phone: "01512345678", username: "shahin", password: "123", online: false, tasks: 0 }
  ],
  orders: []
};

function ensureDb() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, JSON.stringify(defaultDb, null, 2), "utf8");
}

function readDb() {
  ensureDb();
  const db = JSON.parse(fs.readFileSync(DB_FILE, "utf8"));
  let dirty = false;
  if (db.riders) {
    db.riders.forEach(r => {
      if (!r.username) {
        r.username = r.id.replace("rider_", "");
        dirty = true;
      }
      if (!r.password) {
        r.password = "123";
        dirty = true;
      }
    });
  }
  if (dirty) {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), "utf8");
  }
  return db;
}

function writeDb(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), "utf8");
}

function sendJson(res, status, data) {
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  });
  res.end(JSON.stringify(data));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", chunk => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error("Request body too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });
    req.on("error", reject);
  });
}

function createOrderId(db) {
  const max = db.orders.reduce((highest, order) => {
    const n = Number(String(order.id).replace(/\D/g, ""));
    return Number.isFinite(n) ? Math.max(highest, n) : highest;
  }, 1234);
  return `ORD-${max + 1}`;
}

function serveStatic(req, res, pathname) {
  const filePath = pathname === "/" ? path.join(ROOT, "index.html") : path.join(ROOT, pathname);
  const normalized = path.normalize(filePath);
  if (!normalized.startsWith(ROOT)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }
  fs.readFile(normalized, (error, buffer) => {
    if (error) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }
    const ext = path.extname(normalized).toLowerCase();
    const types = {
      ".html": "text/html; charset=utf-8",
      ".js": "text/javascript; charset=utf-8",
      ".css": "text/css; charset=utf-8",
      ".json": "application/json; charset=utf-8",
      ".png": "image/png",
      ".jpg": "image/jpeg",
      ".jpeg": "image/jpeg"
    };
    res.writeHead(200, { "Content-Type": types[ext] || "application/octet-stream" });
    res.end(buffer);
  });
}

async function handleApi(req, res, pathname) {
  if (req.method === "OPTIONS") return sendJson(res, 200, { ok: true });
  const db = readDb();

  if (req.method === "GET" && pathname === "/api/health") {
    return sendJson(res, 200, { ok: true, app: "Dupa Bari Backend", time: new Date().toISOString() });
  }

  if (req.method === "GET" && pathname === "/api/bootstrap") {
    return sendJson(res, 200, db);
  }

  if (req.method === "GET" && pathname === "/api/prices") {
    return sendJson(res, 200, db.prices);
  }

  if (req.method === "POST" && pathname === "/api/prices") {
    const body = await readBody(req);
    const { id, name, category, wash, dry, combo, iron } = body;
    if (!name) return sendJson(res, 400, { error: "Item name is required" });

    let item = db.prices.find(p => p.id === id || p.name === name);
    if (item) {
      item.name = name || item.name;
      item.category = category || item.category;
      item.wash = wash !== undefined ? Number(wash) : item.wash;
      item.dry = dry !== undefined ? Number(dry) : item.dry;
      item.combo = combo !== undefined ? Number(combo) : item.combo;
      item.iron = iron !== undefined ? Number(iron) : item.iron;
    } else {
      const generatedId = id || `item_${Date.now()}`;
      item = {
        id: generatedId,
        name,
        category: category || "male",
        wash: Number(wash || 0),
        dry: Number(dry || 0),
        combo: Number(combo || 0),
        iron: Number(iron || 0)
      };
      db.prices.push(item);
    }

    writeDb(db);
    return sendJson(res, 200, item);
  }

  if (req.method === "GET" && pathname === "/api/orders") {
    return sendJson(res, 200, db.orders);
  }

  if (req.method === "POST" && pathname === "/api/orders") {
    const body = await readBody(req);
    const subtotal = Number(body.subtotal || 0);
    const discount = 0;
    const delivery = subtotal > 0 && subtotal < 300 ? 30 : 0;
    const order = {
      id: createOrderId(db),
      customerName: body.customerName || "রহিম উদ্দিন",
      phone: body.phone || "০১৭XXXXXXXX",
      address: body.address || "কলাতলী, কক্সবাজার",
      service: body.service || "ওয়াশ",
      items: Array.isArray(body.items) ? body.items : [],
      subtotal,
      delivery,
      discount,
      total: Math.max(subtotal + delivery - discount, 0),
      deliveryTime: body.deliveryTime || "Pickup After 3-7 Day Complete",
      payment: body.payment || "COD",
      status: body.status || "অর্ডার পেন্ডিং",
      riderId: body.riderId || "rider_karim",
      createdAt: new Date().toISOString()
    };
    db.orders.unshift(order);
    const cleanPhone = normalizePhone(order.phone);
    const customer = db.customers.find(item => normalizePhone(item.phone) === cleanPhone);
    if (customer) customer.orders += 1;
    else db.customers.push({ id: `cus_${Date.now()}`, name: order.customerName, phone: order.phone, address: order.address, orders: 1 });
    writeDb(db);
    return sendJson(res, 201, order);
  }

  const orderStatusMatch = pathname.match(/^\/api\/orders\/([^/]+)\/status$/);
  if (req.method === "PATCH" && orderStatusMatch) {
    const body = await readBody(req);
    const order = db.orders.find(item => item.id === orderStatusMatch[1]);
    if (!order) return sendJson(res, 404, { error: "Order not found" });
    order.status = body.status || order.status;
    order.riderId = body.riderId || order.riderId;
    order.updatedAt = new Date().toISOString();
    writeDb(db);
    return sendJson(res, 200, order);
  }

  // DELETE /api/orders/:id — Customer-initiated cancellation (only if still pending)
  const orderDeleteMatch = pathname.match(/^\/api\/orders\/([^/]+)$/);
  if (req.method === "DELETE" && orderDeleteMatch) {
    const orderId = orderDeleteMatch[1];
    const idx = db.orders.findIndex(item => item.id === orderId);
    if (idx === -1) return sendJson(res, 404, { error: "Order not found" });
    const order = db.orders[idx];
    const pendingStatuses = ["অর্ডার পেন্ডিং", "Order Pending", "pending"];
    const isPending = pendingStatuses.some(s => (order.status || "").includes(s) || (order.status || "") === s);
    if (!isPending) {
      return sendJson(res, 403, { error: "Cannot cancel an order that is already being processed" });
    }
    db.orders.splice(idx, 1);
    // Clean up messages for this order too
    if (db.messages && db.messages[orderId]) {
      delete db.messages[orderId];
    }
    writeDb(db);
    return sendJson(res, 200, { ok: true, cancelled: orderId });
  }

  const orderMessagesMatch = pathname.match(/^\/api\/orders\/([^/]+)\/messages$/);
  if (orderMessagesMatch) {
    const orderId = orderMessagesMatch[1];
    if (req.method === "GET") {
      if (!db.messages) db.messages = {};
      const list = db.messages[orderId] || [];
      return sendJson(res, 200, list);
    }
    if (req.method === "POST") {
      const body = await readBody(req);
      if (!db.messages) db.messages = {};
      if (!db.messages[orderId]) db.messages[orderId] = [];
      const msg = {
        id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
        text: body.text || "",
        sender: body.sender || "customer",
        createdAt: new Date().toISOString()
      };
      db.messages[orderId].push(msg);
      writeDb(db);
      return sendJson(res, 201, msg);
    }
  }

  // GET /api/customers/:phone/orders — fetch all orders by a phone number
  const custOrdersMatch = pathname.match(/^\/api\/customers\/([^/]+)\/orders$/);
  if (req.method === "GET" && custOrdersMatch) {
    const phone = decodeURIComponent(custOrdersMatch[1]);
    const custOrders = db.orders.filter(o => o.phone === phone);
    return sendJson(res, 200, custOrders);
  }

  if (req.method === "GET" && pathname === "/api/customers") {
    return sendJson(res, 200, db.customers);
  }

  if (req.method === "POST" && pathname === "/api/customers") {
    const body = await readBody(req);
    const phone = body.phone || "";
    const cleanPhone = normalizePhone(phone);
    const existing = db.customers.find(customer => normalizePhone(customer.phone) === cleanPhone);
    const customer = {
      id: existing?.id || `cus_${Date.now()}`,
      name: body.name || body.customerName || "গ্রাহক",
      phone,
      area: body.area || "",
      address: body.address || "",
      orders: existing?.orders || 0,
      updatedAt: new Date().toISOString()
    };
    if (existing) Object.assign(existing, customer);
    else db.customers.push(customer);
    writeDb(db);
    return sendJson(res, existing ? 200 : 201, customer);
  }

  // GET /api/riders/:id/orders — fetch all orders assigned to a rider
  const riderOrdersMatch = pathname.match(/^\/api\/riders\/([^/]+)\/orders$/);
  if (req.method === "GET" && riderOrdersMatch) {
    const riderId = decodeURIComponent(riderOrdersMatch[1]);
    const riderOrders = db.orders.filter(o => o.riderId === riderId);
    return sendJson(res, 200, riderOrders);
  }

  if (req.method === "GET" && pathname === "/api/riders") {
    return sendJson(res, 200, db.riders);
  }

  if (req.method === "POST" && pathname === "/api/riders") {
    const body = await readBody(req);
    const { name, phone, username, password } = body;
    if (!name || !phone || !username || !password) {
      return sendJson(res, 400, { error: "সবগুলো ফিল্ড (নাম, ফোন, ইউজারনেম, পাসওয়ার্ড) পূরণ করা আবশ্যক" });
    }
    const exists = db.riders.some(r => r.username === username || r.phone === phone);
    if (exists) {
      return sendJson(res, 400, { error: "এই ইউজারনেম বা ফোন নম্বরের রাইডার ইতিমধ্যেই বিদ্যমান রয়েছে" });
    }
    const newRider = {
      id: `rider_${Date.now()}`,
      name,
      phone,
      username,
      password,
      online: false,
      tasks: 0
    };
    db.riders.push(newRider);
    writeDb(db);
    return sendJson(res, 201, newRider);
  }

  if (req.method === "POST" && pathname === "/api/auth/admin") {
    const body = await readBody(req);
    const { username, password } = body;
    if (username === "ADMIN" && password === "admin2026") {
      return sendJson(res, 200, { ok: true, role: "admin", token: "admin-token-demo" });
    } else {
      return sendJson(res, 401, { error: "ভুল ইউজারনেম অথবা পাসওয়ার্ড" });
    }
  }

  if (req.method === "POST" && pathname === "/api/auth/rider-login") {
    const body = await readBody(req);
    const { username, password } = body;
    const rider = db.riders.find(r => r.username === username && r.password === password);
    if (rider) {
      return sendJson(res, 200, { ok: true, riderId: rider.id, name: rider.name, token: "rider-token-demo" });
    } else {
      return sendJson(res, 401, { error: "ভুল ইউজারনেম অথবা পাসওয়ার্ড" });
    }
  }

  if (req.method === "POST" && pathname === "/api/auth/otp") {
    const body = await readBody(req);
    return sendJson(res, 200, { ok: true, phone: body.phone || "", otp: "1234", message: "Prototype OTP generated" });
  }

  if (req.method === "POST" && pathname === "/api/auth/verify") {
    const body = await readBody(req);
    const phone = body.phone || "";
    const cleanPhone = normalizePhone(phone);
    const customer = db.customers.find(c => normalizePhone(c.phone) === cleanPhone);
    return sendJson(res, 200, { ok: body.otp === "1234" || body.otp === undefined, token: "demo-token", user: customer || null });
  }

  if (req.method === "POST" && pathname === "/api/auth/register") {
    const body = await readBody(req);
    const phone = body.phone || "";
    const password = body.password || "";
    const cleanPhone = normalizePhone(phone);
    if (!cleanPhone || !password) {
      return sendJson(res, 400, { error: "ফোন নম্বর ও পাসওয়ার্ড আবশ্যক" });
    }
    const existing = db.customers.find(c => normalizePhone(c.phone) === cleanPhone);
    if (existing) {
      return sendJson(res, 400, { error: "এই নম্বরে অ্যাকাউন্ট ইতিমধ্যেই আছে, লগইন করুন" });
    }
    const customer = {
      id: `cus_${Date.now()}`,
      name: body.name || "",
      phone,
      password,
      area: "",
      address: "",
      orders: 0
    };
    db.customers.push(customer);
    writeDb(db);
    const { password: _pw, ...safeCustomer } = customer;
    return sendJson(res, 201, { ok: true, token: "demo-token", user: safeCustomer });
  }

  if (req.method === "POST" && pathname === "/api/auth/login") {
    const body = await readBody(req);
    const cleanPhone = normalizePhone(body.phone || "");
    const password = body.password || "";
    const customer = db.customers.find(c => normalizePhone(c.phone) === cleanPhone);
    if (!customer) {
      return sendJson(res, 401, { error: "এই নম্বরে কোনো অ্যাকাউন্ট নেই, একাউন্ট তৈরি করুন" });
    }
    if (customer.password !== password) {
      return sendJson(res, 401, { error: "ভুল পাসওয়ার্ড" });
    }
    const { password: _pw, ...safeCustomer } = customer;
    return sendJson(res, 200, { ok: true, token: "demo-token", user: safeCustomer });
  }

  if (req.method === "POST" && pathname === "/api/auth/reset-password") {
    const body = await readBody(req);
    const cleanPhone = normalizePhone(body.phone || "");
    const customer = db.customers.find(c => normalizePhone(c.phone) === cleanPhone);
    if (!customer) {
      return sendJson(res, 401, { error: "এই নম্বরে কোনো অ্যাকাউন্ট নেই" });
    }
    if (body.otp !== "1234") {
      return sendJson(res, 401, { error: "ভুল কোড" });
    }
    if (!body.newPassword) {
      return sendJson(res, 400, { error: "নতুন পাসওয়ার্ড আবশ্যক" });
    }
    customer.password = body.newPassword;
    writeDb(db);
    return sendJson(res, 200, { ok: true });
  }

  return sendJson(res, 404, { error: "API route not found" });
}

const server = http.createServer(async (req, res) => {
  try {
    const { pathname } = new URL(req.url, `http://${req.headers.host}`);
    if (pathname.startsWith("/api/")) return await handleApi(req, res, pathname);
    return serveStatic(req, res, decodeURIComponent(pathname));
  } catch (error) {
    return sendJson(res, 500, { error: error.message || "Server error" });
  }
});

ensureDb();
server.listen(PORT, () => {
  console.log(`Dupa Bari app running at http://localhost:${PORT}`);
  console.log(`API health: http://localhost:${PORT}/api/health`);
});
