# Dhopa Bari — Backend

Node.js + Express + PostgreSQL (via Prisma) REST API for the Dhopa Bari
laundry platform. Serves the Flutter customer app, Flutter rider app, and
React admin panel.

## Stack

- **Express** — HTTP API, JSON only (no server-rendered views)
- **PostgreSQL + Prisma** — database and ORM (`prisma/schema.prisma`)
- **Firebase Admin SDK** — verifies ID tokens issued by Firebase Auth on the
  client (Google Login, Phone/OTP Login); the API then issues its own JWT
  for subsequent requests
- **JWT** — stateless session tokens (`Authorization: Bearer <token>`),
  role-based (`CUSTOMER` / `RIDER` / `ADMIN`)
- **Cloudinary** — image uploads (chat photos, avatars)
- **Google Maps Geocoding API** — address → lat/lng (optional; falls back to
  manual lat/lng entry if unset)
- **bKash / Nagad / SSLCommerz** — payment gateway integration points
  (scaffolded, not yet implemented — see below)

## Getting started

```bash
cd backend
cp .env.example .env        # then fill in DATABASE_URL at minimum
npm install
npm run prisma:migrate      # creates tables from schema.prisma
npm run seed                # seeds services, categories, prices, admin user, FIRST10 coupon
npm run dev                 # starts on http://localhost:4000
```

Or via Docker (spins up Postgres + backend together):

```bash
# from the repo root
docker compose up --build
```

## What works today vs. what needs your credentials

| Feature | Status |
|---|---|
| Customer register/login (phone + password) | ✅ fully functional once `DATABASE_URL` is set |
| Admin / Rider login (phone + password) | ✅ fully functional |
| Orders, pricing, coupons, addresses, chat, notifications (in-app) | ✅ fully functional |
| Order status flow + push-notification records | ✅ writes `Notification` rows always; **actually delivers** a push only if Firebase is configured |
| Google/Phone login via Firebase | ⚠️ code path exists (`/api/auth/firebase-login`), but needs `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` in `.env`. Without them the API runs in **dev mode**: it accepts a fake token `DEMO_TOKEN:<phone>` instead of a real Firebase ID token, so the whole flow is testable before you have a Firebase project. |
| Image uploads | ⚠️ needs `CLOUDINARY_*` vars — returns `503` until set |
| Google Maps geocoding | ⚠️ needs `GOOGLE_MAPS_API_KEY` — returns `null` (client should fall back to manual address entry) until set |
| bKash / Nagad / SSLCommerz payments | ❌ **not implemented** — each provider requires a merchant account and a distinct tokenized/RSA-signed checkout flow. `src/services/paymentService.js` has the call sites and `TODO`s wired to real credentials; the actual HTTP integration needs to be built once you have sandbox credentials from each provider. Cash on Delivery works today with no configuration. |

## Project structure

```
backend/
  prisma/
    schema.prisma      normalized DB schema (Users, Orders, OrderItems,
                        Addresses, Payments/Transactions, Coupons,
                        Notifications, Chats, Messages, Riders, Services,
                        Categories, Settings, Reviews, Withdrawals)
    seed.js             seeds Wash/Dry Clean services, Men/Women/Kids/Home
                        categories + prices, an admin account, FIRST10 coupon
  src/
    app.js              Express app + route wiring
    server.js            entry point
    config/              env loading, Prisma client singleton
    middleware/           JWT auth, role authorization, validation, rate
                          limiting, error handling
    controllers/          one file per resource (auth, users, catalog,
                          orders, coupons, notifications, chats, riders,
                          admin, uploads)
    routes/                Express routers, one per controller
    services/              firebaseAdmin, cloudinaryService, mapsService,
                          paymentService, notify (push + in-app notification
                          helper)
    utils/                jwt, order number generator, PDF invoice
                          generator, zod validators
```

## API surface (high level)

- `POST /api/auth/register` / `login` — customer phone+password
- `POST /api/auth/firebase-login` — Google/Phone login via Firebase ID token
- `POST /api/auth/admin-login`, `/api/auth/rider-login`
- `POST /api/auth/forgot-password/request`, `/reset`
- `GET /api/catalog` — services, categories, price items (public)
- `POST /api/orders`, `GET /api/orders`, `GET /api/orders/:id`
- `PATCH /api/orders/:id/status`, `/assign-rider` (admin/rider)
- `GET /api/orders/:id/invoice.pdf`
- `POST /api/coupons/validate`, admin CRUD under `/api/coupons`
- `GET/POST /api/chats`, `/api/chats/:id/messages`
- `GET /api/notifications`, `PUT /api/notifications/device-token`
- `GET /api/riders/me/dashboard`, `/earnings`, admin CRUD under `/api/riders`
- `GET /api/admin/dashboard`, `/reports`, `/customers`, `/settings`
- `POST /api/uploads` — Cloudinary image upload
- `POST /api/payments/initiate` — bKash/Nagad/SSLCommerz (501 until implemented)

## Security

- Passwords hashed with bcrypt (10 rounds)
- JWT-based sessions, role checks via `authorize('ADMIN' | 'RIDER' | 'CUSTOMER')` middleware
- `helmet` security headers, `express-rate-limit` on all `/api` routes (tighter limit on auth routes)
- Zod request validation on auth endpoints
- Blocked users (`isBlocked`) are rejected at the auth middleware layer
