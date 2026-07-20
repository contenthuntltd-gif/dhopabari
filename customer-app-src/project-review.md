# Dhopa Bari — Project Review Report

**কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার**
Report generated: 2026-07-14

---

## 1. Project Overview

### Current phase
**Phase 1 (Backend foundation) — code complete, unverified against a live database.**
**Phase 3 (Customer App UI) — in progress, mock-data preview running.**
Phases 2 (Admin Panel) and 4 (Rider App) have not been started.

### Completion by module

| Module | Status | Est. completion |
|---|---|---|
| Backend API (Node/Express/Prisma) | Code complete for Phase 1 scope; **never run against a real database** | ~45% of full backend scope |
| Customer App (Flutter) | UI complete on mock data; zero backend wiring | ~35% of full customer app scope |
| Admin Panel (React) | Not started | 0% |
| Rider App (Flutter) | Not started (placeholder screen only, lives inside the customer app) | ~2% |
| Database (PostgreSQL) | Installed, running as a service; schema written; **no migration ever applied, no data exists** | Schema design 100%, live DB 0% |
| Legacy prototype (Expo/RN + Node/JSON) | Fully functional, end-to-end, archived | 100% of its own (smaller) scope |

**Overall, against the full original specification (2 Flutter apps + React admin + full backend + Firebase/Cloudinary/Maps/payment integrations + production deploy): roughly 20–25% complete.** The two largest pieces of remaining work are (a) standing up a real database connection and verifying the backend end-to-end, and (b) building the Admin Panel and Rider App, which do not exist yet.

### Completed modules
- Backend REST API source code (all controllers/routes/middleware/services)
- Prisma database schema (17 models, fully normalized)
- Customer App UI shell — every screen in the core flow, navigable, styled to spec, running in a mobile-frame web preview
- Legacy prototype (kept as a working reference/fallback, not part of forward development)

### Pending modules
- Live database (migrations + seed have never been executed)
- Backend ↔ Customer App integration (currently 100% mock data)
- Admin Panel (entire project — 0 files)
- Rider App (entire project — 0 files, beyond a one-screen placeholder)
- Firebase, Cloudinary, Google Maps, bKash/Nagad/SSLCommerz — none connected to real credentials
- Push notifications (code path exists, nothing to send to — no real device tokens, no Firebase project)

---

## 2. Customer App

Flutter project at `customer-app/`. Currently served on **http://localhost:5000** via `flutter run -d web-server`, wrapped in a fixed 412px mobile frame for desktop browser preview. All data is local mock data in `lib/data/mock_data.dart` — **no network calls exist in this app at all yet.**

| # | Screen (file) | Status | Features completed | Features missing | Navigates to |
|---|---|---|---|---|---|
| 1 | Login (`login_screen.dart`) | ✅ UI complete | Phone+password fields, show/hide password, floating bubble animation, ⋮ bottom-sheet (Admin/Rider account picker), language pill (UI only), Google button (UI only), WhatsApp/Facebook links (UI only), feature strip | No real auth call; "Forgot password" and "Create account" links work but submit nowhere real; language toggle doesn't translate | Register, Forgot Password, Admin Login (stub), Rider Login (stub), Root Shell (on "login") |
| 2 | Register (`register_screen.dart`) | ✅ UI complete | Phone/password/confirm fields, validation (password length, match) | No real account creation | Root Shell (on submit) |
| 3 | Forgot Password (`forgot_password_screen.dart`) | ✅ UI complete | Two-step UI (request code → reset), local state only | No real OTP send/verify | back to Login |
| 4 | Admin Login (`admin_login_screen.dart`) | ⚠️ Placeholder | Branded "not built yet" message | Entire real screen — Admin Panel is a separate React project (Phase 2), doesn't exist | back to Login |
| 5 | Rider Login (`rider_login_screen.dart`) | ⚠️ Placeholder | Branded "not built yet" message | Entire real screen — Rider App is a separate Flutter project (Phase 4), doesn't exist | back to Login |
| 6 | Root Shell (`root_shell.dart`) | ✅ Complete | Bottom-nav container (`IndexedStack`) hosting Home/Orders/Chat/Profile tabs + raised center "New Order" FAB, matches reference design | — | Home, Orders, Chat, Profile, New Order |
| 7 | Home (`home_screen.dart`) | ✅ UI complete | Greeting + location, hero banner, Wash/Dry Clean service cards, ongoing-order card with live progress bar, referral card, notification bell with badge | All data is hardcoded mock; notification bell doesn't open anything | New Order, Tracking, Orders (via "see all") |
| 8 | New Order (`new_order_screen.dart`) | ✅ UI complete | 3-step flow (Service+Category+Items → Address+Pickup time → Summary), stepper header, quantity steppers, live running total | No real pricing API, no address geocoding/map, "Use current location" button is inert, no payment method selection UI | Order Success |
| 9 | Order Success (`order_success_screen.dart`) | ✅ UI complete | Confirmation screen with mock order number | No real order was created | Root Shell |
| 10 | Orders list (`orders_screen.dart`) | ✅ UI complete | List of mock past/ongoing orders | No real data, no filtering/search | Tracking |
| 11 | Tracking (`tracking_screen.dart`) | ✅ UI complete | Visual status timeline, order detail card | Static mock timeline, no live polling/push updates, no map/rider location | — |
| 12 | Chat list (`chat_list_screen.dart`) | ✅ UI complete | Two mock conversations (Support, Rider), unread badges | No real messages, no persistence | Chat thread |
| 13 | Chat thread (`chat_screen.dart`) | ✅ UI complete | Message bubbles, simulated typing indicator, simulated auto-reply, text input, image/emoji buttons (inert) | No real messaging backend, no actual photo/file upload | — |
| 14 | Profile (`profile_screen.dart`) | ✅ UI complete | Avatar, name/phone/area, menu list (addresses, order history, referral, ratings, language, notifications, help, about, privacy, terms), logout | Every menu item except Logout is a no-op | Login (on logout) |

**Navigation flow summary:**
```
Login ──▶ Register ──▶ Root Shell
  │  └──▶ Forgot Password
  │  └──▶ (⋮ sheet) Admin Login stub / Rider Login stub
  └──▶ Root Shell (Home tab)
         ├─ Home ──▶ New Order ──▶ Order Success ──▶ Root Shell
         │        └─▶ Tracking
         ├─ Orders ──▶ Tracking
         ├─ Chat list ──▶ Chat thread
         └─ Profile ──▶ Login (logout)
```

---

## 3. Rider App

**Current progress: not started as a real project.** The specification calls for a separate Flutter project (Phase 4). What exists today is a single placeholder screen (`rider_login_screen.dart`) *inside the customer app*, reachable from the Login screen's account-type sheet, that displays a branded "not built yet" message and a back button.

- **Completed pages:** 0 real pages. 1 placeholder.
- **Pending pages:** Login, Dashboard (today's pickup/delivery, online/offline toggle), Pickup detail (customer info, map, call, complete), Delivery detail (list, navigate, complete), Earnings (today/weekly/monthly, withdrawal, history), Profile.
- **Workflow:** Not implemented. The backend already has the supporting API surface ready for this app (`/api/riders/me/*` — dashboard, online status, location, earnings, withdrawals — see §10), but no Flutter project consumes it.

---

## 4. Admin Panel

**Current progress: not started. Zero files exist.** No `admin/` directory has been created. The spec calls for React + TailwindCSS (Phase 2).

| Section | Status |
|---|---|
| Dashboard | ❌ Not started (backend endpoint `GET /api/admin/dashboard` exists and is ready to consume) |
| Orders | ❌ Not started (backend order-management endpoints exist: list/filter, assign rider, change status, invoice PDF) |
| Customers | ❌ Not started (backend endpoints exist: list/search, block/unblock) |
| Riders | ❌ Not started (backend endpoints exist: create/edit/delete, list) |
| Pricing | ❌ Not started (backend endpoints exist: catalog CRUD for services/categories/price items) |
| Reports | ❌ Not started (backend endpoint exists: daily/weekly/monthly revenue+order series) |
| Settings | ❌ Not started (backend endpoints exist: get/set arbitrary settings by key) |

Every section above has a working backend endpoint already built and ready — the entire gap here is the frontend.

---

## 5. Backend

Node.js + Express + PostgreSQL + Prisma, at `backend/`. **Source code is complete for its planned scope. It has never successfully connected to a live database — this is the single biggest unverified risk in the project.**

| Area | Status | Detail |
|---|---|---|
| **Authentication** | ⚠️ Written, unverified live | Phone+password (customer/admin/rider) via bcrypt; Firebase ID-token verification path exists with a documented dev-mode fallback (`DEMO_TOKEN:<phone>`) since no Firebase project is connected yet |
| **Database** | ❌ Not connected | PostgreSQL 17 installed and running as a Windows service (port 5432), but the `postgres` superuser password was never set — blocked mid-session waiting on the user to set it via pgAdmin/psql. **No migration has ever been run.** |
| **Prisma** | ✅ Schema valid, client generated | `prisma generate` succeeds; `prisma migrate dev` has never been run (needs the DB password above) |
| **API** | ✅ Code complete for Phase 1 | 11 route groups, ~45 endpoints (full list in §10); routing/validation/error-handling verified via smoke test with no DB (see below) |
| **Notifications** | ⚠️ Partial | Every order status change and chat message writes a `Notification` row; actual push delivery via FCM only fires if Firebase credentials are configured (they aren't) — currently logs "would send push" instead |
| **Chat** | ✅ Code complete, unverified live | Support & rider chat, message send/list, read-state — needs a live DB to test |
| **Payments** | ❌ Scaffolded only | Cash on Delivery needs no integration and works as a data field; bKash/Nagad/SSLCommerz each throw a clear `501 Not implemented` — the actual tokenized/signed checkout flows were never built pending real merchant credentials |
| **Order APIs** | ✅ Code complete, unverified live | Full lifecycle: create (with live pricing + coupon validation) → 11-step status flow → rider assignment → cancel → PDF invoice |

**What was actually verified this session (without a database):** server starts cleanly; `/api/health` responds; Zod validation rejects bad input before touching the DB; missing-auth and 404 routes return correct structured errors; a real bug was found and fixed (Prisma's internal error messages/file paths were leaking into API responses — now sanitized outside dev mode). **What was not verified:** any actual read/write to Postgres — register, login, create-order, etc. have only been code-reviewed, not executed successfully end-to-end.

---

## 6. Database

PostgreSQL via Prisma, schema at `backend/prisma/schema.prisma`. **17 tables, fully normalized. Schema is designed and validated but not yet migrated to a live database — none of this exists as actual tables yet.**

### Tables

| Table | Purpose |
|---|---|
| `users` | All accounts (customer/rider/admin), role-based, phone+password or Firebase UID |
| `rider_profiles` | 1:1 extension of a `RIDER` user — bike number, area, online status, live lat/lng, rating, wallet balance |
| `addresses` | Saved customer addresses, multiple per user, one default |
| `services` | Wash, Dry Clean (only 2, per spec) |
| `categories` | Men, Women, Kids, Home |
| `price_items` | Per-item price, unique per (category, service, item name) |
| `orders` | Core order record — status, pickup/delivery timing, pricing breakdown, payment method/status |
| `order_items` | Line items on an order, price-snapshotted at order time |
| `order_status_logs` | Full audit trail of every status change (who, when, note) |
| `coupons` | Percent/fixed discounts, usage limits, expiry |
| `notifications` | In-app + push notification records, per-user or broadcast |
| `chats` | Support or rider conversation threads, optionally tied to an order |
| `messages` | Individual chat messages — text, image, file, read state |
| `reviews` | Post-delivery rating for service + rider |
| `transactions` | Payment records (COD/bKash/Nagad/SSLCommerz), gateway reference |
| `withdrawal_requests` | Rider payout requests against their wallet balance |
| `settings` | Arbitrary key/value store for admin-configurable settings (business info, banners, terms, etc.) |

### Key relationships
- `User` 1—1 `RiderProfile` (only for `RIDER` role)
- `User` 1—N `Address`, `Order` (as customer), `Notification`, `Message` (as sender)
- `RiderProfile` 1—N `Order` (as assigned rider), `Chat` (as rider), `WithdrawalRequest`
- `Order` N—1 `User` (customer), `RiderProfile` (rider, nullable), `Service`, `Address`, `Coupon` (nullable)
- `Order` 1—N `OrderItem`, `OrderStatusLog`, `Chat`, `Transaction`; 1—1 `Review`
- `Category` 1—N `PriceItem`; `Service` 1—N `PriceItem` (a `PriceItem` is the price of one item under one category+service combination)
- `Chat` 1—N `Message`

---

## 7. Order Flow

The full lifecycle as modeled by the backend (customer app currently only simulates this with mock data):

1. **Browse & build order** — customer loads `GET /api/catalog` (services, categories, price items), selects a service, category, and items with quantities.
2. **Address & schedule** — customer selects/creates a pickup `Address`, picks a pickup date + time slot.
3. **Coupon (optional)** — `POST /api/coupons/validate` checks eligibility and computes discount.
4. **Create order** — `POST /api/orders` atomically: prices every line item server-side (never trusts client prices), applies discount, creates the `Order` + `OrderItem` rows + an initial `PENDING` entry in `OrderStatusLog`, increments coupon usage. A `Notification` is created for the customer.
5. **Admin accepts** — admin changes status to `ACCEPTED` via `PATCH /api/orders/:id/status`.
6. **Rider assignment** — admin calls `PATCH /api/orders/:id/assign-rider`; status becomes `RIDER_ASSIGNED`; both customer and rider are notified.
7. **Pickup** — rider marks `PICKED_UP` from their dashboard.
8. **Processing** — status progresses through `REACHED_LAUNDRY` → `WASHING` → `QUALITY_CHECK` → `PACKED`, each a status-log entry + customer notification.
9. **Delivery** — rider marks `OUT_FOR_DELIVERY`, then `DELIVERED` (this also stamps `deliveryDate` and increments the rider's `totalDeliveries`).
10. **Post-delivery** — customer can leave a `Review` (service + rider rating); payment is reconciled via `Transaction` records if a digital payment method was used.
11. **Cancellation** — customer or admin can cancel any time before `DELIVERED`, which is a terminal `CANCELLED` status.

Every step above writes an `OrderStatusLog` row (full audit trail) and attempts a push notification — but as noted in §5, this entire flow has only been code-reviewed, not executed against a live order, since there's no database yet.

---

## 8. UI Structure (Customer App)

```
Splash
  └─ (no separate splash screen exists — app opens directly to Login)
Login
  ├─ Register
  ├─ Forgot Password
  └─ (⋮ menu) Admin Login stub / Rider Login stub
Root Shell (bottom nav)
  ├─ Home
  │    ├─ New Order (3-step: Service+Items → Address+Time → Summary)
  │    │    └─ Order Success ─▶ back to Root Shell
  │    └─ Tracking
  ├─ Orders ─▶ Tracking
  ├─ Chat list ─▶ Chat thread
  └─ Profile ─▶ Logout ─▶ Login
```

Note: the spec listed "Splash" as its own screen; the current implementation skips straight to Login with no splash/loading screen.

---

## 9. Folder Structure

```
Dopa Bari/
├── README.md                       root-level phase-status doc
├── docker-compose.yml               Postgres + backend (admin service commented out, doesn't exist yet)
├── .gitignore
│
├── backend/                         Node.js + Express + PostgreSQL + Prisma
│   ├── .env / .env.example
│   ├── Dockerfile, .dockerignore
│   ├── package.json
│   ├── README.md
│   ├── prisma/
│   │   ├── schema.prisma            17 models
│   │   └── seed.js                  services, categories, prices, admin/rider/customer test accounts, FIRST10 coupon
│   └── src/
│       ├── app.js, server.js
│       ├── config/                  env.js, prisma.js
│       ├── middleware/               auth.js, errorHandler.js, rateLimit.js, validate.js
│       ├── controllers/               auth, users, catalog, orders, coupons, notifications, chats, riders, admin, uploads (10 files)
│       ├── routes/                    one router per controller (11 files)
│       ├── services/                  firebaseAdmin, cloudinaryService, mapsService, paymentService, notify
│       └── utils/                     jwt, orderNumber, pdf, validators
│
├── customer-app/                    Flutter (web/android/ios targets scaffolded)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme/app_theme.dart
│   │   ├── data/mock_data.dart
│   │   ├── widgets/                  app_bottom_nav.dart, bn_number.dart, phone_frame.dart
│   │   └── screens/                  14 screen files (see §2)
│   ├── web/, android/, ios/           platform scaffolding from `flutter create`
│   └── test/widget_test.dart
│
├── legacy-prototype/                 ARCHIVED — earlier Expo/React Native + Node(JSON-file) build
│   ├── index.html                    standalone web prototype
│   ├── server.js                     JSON-file-backed API (no Postgres)
│   ├── mobile/                       Expo/React Native app (login, home, admin screens)
│   └── data/                         JSON "database"
│
└── (not yet created)
    ├── admin/                        React + Tailwind admin panel — Phase 2
    └── rider-app/                    Flutter rider app — Phase 4
```

---

## 10. APIs

Base URL: `http://localhost:4000/api` (when running — currently stopped).

### Auth (`/api/auth`)
| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/register` | — | Customer sign-up (phone+password) |
| POST | `/login` | — | Customer login |
| POST | `/firebase-login` | — | Google/Phone login via Firebase ID token |
| POST | `/admin-login` | — | Admin login |
| POST | `/rider-login` | — | Rider login |
| POST | `/forgot-password/request` | — | Confirms account exists |
| POST | `/forgot-password/reset` | — | Resets password after Firebase phone verification |
| GET | `/me` | JWT | Current user profile |

### Users (`/api/users`) — all JWT-protected
| Method | Path | Purpose |
|---|---|---|
| PATCH | `/me` | Update name/email/avatar |
| GET | `/me/addresses` | List saved addresses |
| POST | `/me/addresses` | Add address |
| DELETE | `/me/addresses/:id` | Remove address |

### Catalog (`/api/catalog`)
| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/` | public | Services + categories + price items |
| POST | `/price-items` | Admin | Create/update a price |
| DELETE | `/price-items/:id` | Admin | Deactivate a price item |
| POST | `/categories` | Admin | Add category |
| POST | `/services` | Admin | Add service |

### Orders (`/api/orders`) — all JWT-protected
| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/` | Customer | Create order |
| GET | `/` | any role | List (scoped by role) + filter by status/search |
| GET | `/:id` | owner/rider/admin | Order detail |
| GET | `/:id/invoice.pdf` | owner/rider/admin | PDF invoice |
| PATCH | `/:id/status` | rider/admin | Advance/cancel status |
| PATCH | `/:id/assign-rider` | Admin | Assign a rider |
| DELETE | `/:id` | owner/admin | Cancel order |

### Coupons (`/api/coupons`)
| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/validate` | JWT | Check + price a coupon |
| GET / POST / PATCH / DELETE | `/`, `/:id` | Admin | Manage coupons |

### Notifications (`/api/notifications`) — all JWT-protected
| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/` | any | List mine + broadcast |
| PATCH | `/:id/read` | any | Mark read |
| PUT | `/device-token` | any | Register FCM token |
| POST | `/broadcast` | Admin | Send announcement to all users |

### Chats (`/api/chats`) — all JWT-protected
| Method | Path | Purpose |
|---|---|---|
| GET | `/` | List my chats |
| POST | `/` | Start a support or rider chat |
| GET | `/:id/messages` | List messages |
| POST | `/:id/messages` | Send a message |

### Riders (`/api/riders`)
| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/me/dashboard` | Rider | Today's pickups/deliveries, active orders |
| PATCH | `/me/online` | Rider | Toggle online/offline |
| PATCH | `/me/location` | Rider | Update live lat/lng |
| GET | `/me/earnings` | Rider | Wallet balance, delivery count, withdrawal history |
| POST | `/me/withdrawals` | Rider | Request payout |
| GET / POST / PATCH / DELETE | `/`, `/:id` | Admin | Manage riders |

### Admin (`/api/admin`) — all Admin-only
| Method | Path | Purpose |
|---|---|---|
| GET | `/dashboard` | Order counts, revenue, latest orders |
| GET | `/reports` | Daily/weekly/monthly revenue+order series |
| GET | `/customers` | Search/list customers |
| PATCH | `/customers/:id/block` | Block/unblock |
| GET | `/settings` | All settings |
| PUT | `/settings/:key` | Update a setting |

### Uploads / Payments
| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/uploads` | JWT | Cloudinary image upload (503 until configured) |
| POST | `/api/payments/initiate` | JWT | bKash/Nagad/SSLCommerz (currently 501 — not implemented) |

---

## 11. Features

| Feature | Status |
|---|---|
| Phone+password auth (all 3 roles) | ✅ Code complete, ⚠️ unverified live |
| Firebase Google/Phone login | ⚠️ Code path exists, needs real Firebase project |
| JWT sessions + role-based access | ✅ Code complete, ⚠️ unverified live |
| Order creation with server-side pricing | ✅ Code complete, ⚠️ unverified live |
| 11-step order status flow + audit log | ✅ Code complete, ⚠️ unverified live |
| Coupons | ✅ Code complete, ⚠️ unverified live |
| In-app notifications | ✅ Code complete, ⚠️ unverified live |
| Push notifications (FCM) | ⚠️ Wired but inert (no Firebase project) |
| Chat (support + rider) | ✅ Code complete, ⚠️ unverified live |
| Image upload | ⚠️ Wired but inert (no Cloudinary account) |
| Google Maps geocoding | ⚠️ Wired but inert (no API key) |
| PDF invoices | ✅ Code complete (dependency-free generator), ⚠️ unverified live |
| Payments (COD) | ✅ Works (just a data field) |
| Payments (bKash/Nagad/SSLCommerz) | ❌ Not implemented (501) |
| Customer App UI (all core screens) | ✅ Complete on mock data |
| Customer App ↔ Backend integration | ❌ Not started |
| Admin Panel | ❌ Not started |
| Rider App | ❌ Not started |
| Rating/Review | ⚠️ DB model + no UI or endpoint wiring beyond the schema |
| Referral | ⚠️ UI card only (Home screen), no logic anywhere |

---

## 12. Security

| Area | Status |
|---|---|
| **Password storage** | bcrypt, 10 rounds — no plaintext passwords anywhere in the current backend |
| **JWT** | Signed app tokens (`jsonwebtoken`), configurable expiry, verified on every protected route via `authenticate` middleware |
| **Firebase** | `firebase-admin` verifies real ID tokens when configured; dev-mode fallback (`DEMO_TOKEN:<phone>`) only accepted when no Firebase project is configured, clearly logged as such |
| **Role permissions** | `authorize('ADMIN' | 'RIDER' | 'CUSTOMER')` middleware on every role-restricted route; ownership checks in controllers (e.g., a customer can only see their own orders/addresses) |
| **Blocked users** | Rejected at the auth middleware layer (`isBlocked` flag) |
| **Rate limiting** | `express-rate-limit` — 300 req/15min general, 20 req/15min on auth routes |
| **Input validation** | Zod schemas on all auth endpoints; manual checks elsewhere |
| **Security headers** | `helmet` |
| **Error leakage** | Fixed this session — Prisma's internal error messages/stack traces no longer leak into API responses outside dev mode |
| **Secrets** | `.env` gitignored; `.env.example` documents every variable with no real secrets committed |
| **Known gap** | No CSRF protection (acceptable for a pure JSON API consumed by native apps, but relevant once/if the Admin Panel is a browser SPA with cookie-based sessions — currently everything is Bearer-token based, which is CSRF-safe by design) |

---

## 13. Missing Features

- **Admin Panel** — the entire project (dashboard, orders, customers, riders, pricing, coupons, reports, settings UI)
- **Rider App** — the entire project (login, dashboard, pickup/delivery workflow, earnings, profile)
- **Live database** — no migration has ever been run; nothing has been verified against real Postgres
- **Customer App ↔ Backend wiring** — every screen in the customer app currently reads/writes only local mock data
- **Firebase project** — no real Google/Phone login, no real push notifications
- **Cloudinary account** — no real image uploads (chat photos, avatars, banners)
- **Google Maps API key** — no real geocoding, no map display anywhere, no rider navigation
- **bKash/Nagad/SSLCommerz** — payment gateway integrations are stubs that return 501
- **Splash screen** — spec calls for one; app currently opens directly to Login
- **Referral logic** — UI exists, no backend logic
- **Rating/Review UI** — DB model exists, no screen or API wiring surfaced to users
- **Language switching** — toggle button exists on Login but doesn't actually translate anything
- **Search/filter on Orders list** (customer app) — not implemented
- **Multi-language (bn/en) content** — customer app is Bengali-only; no i18n system wired up despite the language toggle UI

---

## 14. Bugs / Known Issues

### Backend
- **No live database** — this isn't a "bug" so much as the fact that nothing has been runtime-tested beyond routing/validation with a disconnected DB. Any Prisma query bug (typo in a relation name, wrong `include`, etc.) will only surface once real migrations run.
- One real bug **found and fixed** this session: Prisma error messages (including file paths) were leaking into JSON error responses in all environments — now sanitized outside `NODE_ENV=development`.
- `npm audit` reports 8 moderate-severity transitive vulnerabilities, all from `firebase-admin`'s dependency chain (`uuid` buffer-bounds issue). Fixing requires a major `firebase-admin` version bump (breaking change) — deferred since Firebase isn't connected yet anyway.

### Customer App
- No errors from `flutter analyze` (0 errors, 0 warnings). 17 informational notices remain, all `withOpacity`/`Radio.groupValue` API-deprecation hints from a newer Flutter API — cosmetic, non-blocking, don't affect behavior.
- `flutter run -d chrome` fails to establish its debug websocket in this environment ("Failed to establish connection with the application instance in Chrome") — worked around by using the `web-server` target instead, which serves the same app without needing that debug handshake. This only affects the *dev workflow* (hot reload via Chrome DevTools); it doesn't affect the app itself.
- Every interactive element that isn't part of the core navigation flow (notification bell, profile menu items besides logout, image/emoji buttons in chat, "use current location") is currently a visual no-op.

### Admin / Rider apps
- N/A — don't exist yet, so no bugs to report.

---

## 15. Future Improvements / Production-Readiness Recommendations

1. **Unblock the database immediately** — set the PostgreSQL superuser password, run `prisma migrate dev` + `npm run seed`, then re-verify every backend endpoint end-to-end (register → login → create order → status flow → chat) before building anything else on top of it.
2. **Wire the customer app to the real backend** before adding more UI — replace `mock_data.dart` reads with `http`/`dio` calls to the now-verified API; this will surface integration bugs early rather than after the Admin Panel and Rider App are also built against assumptions.
3. **Build the Admin Panel next** (Phase 2) — every backend endpoint it needs already exists; this is now the fastest path to a demoable full loop (admin can see and manage orders that the customer app creates).
4. **Get real credentials sooner rather than later** for Firebase, Cloudinary, and Google Maps — these are currently invisible gaps (everything *looks* done because of graceful dev-mode fallbacks) that will each take real setup time once you're ready.
5. **Decide on payment gateway priority** — bKash, Nagad, and SSLCommerz are three separate, non-trivial integrations (tokenized OAuth, RSA-signed payloads, and hosted checkout respectively). Recommend picking one to implement first based on actual merchant account availability rather than building all three speculatively.
6. **Add automated tests** — there are currently no backend integration tests and only a single Flutter smoke test. Once the DB is live, add at minimum: auth flow, order creation/status transitions, and role-permission boundary tests.
7. **Add a splash screen and real i18n** to close the gap with the original spec (currently Bengali-only with a non-functional language toggle).
8. **Plan CI** — no GitHub Actions/CI pipeline exists yet; worth adding once there's a real git repository (this project isn't currently under version control at all).
9. **Address the `firebase-admin` transitive vulnerabilities** before going to production, once Firebase is actually wired up.
10. **Revisit the "dev mode" fallbacks before launch** — the `DEMO_TOKEN:<phone>` Firebase bypass and the hardcoded `1234` OTP demo code must be confirmed disabled/impossible in production (they're already gated behind "Firebase not configured," but worth an explicit pre-launch checklist item).
