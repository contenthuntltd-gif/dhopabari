# Dhopa Bari

কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার — premium digital laundry service, Cox's Bazar Sadar.

Production platform being rebuilt to spec across four projects:

| Project | Stack | Status |
|---|---|---|
| `backend/` | Node.js + Express + PostgreSQL + Prisma | ✅ **Phase 1 — built this session.** REST API, JWT auth, role-based access, full schema. See [backend/README.md](backend/README.md) for setup and what's live vs. what needs your credentials. |
| `admin/` | React + TailwindCSS | ⏳ Phase 2 — not started |
| `customer-app/` | Flutter | ⏳ Phase 3 — not started |
| `rider-app/` | Flutter | ⏳ Phase 4 — not started |
| `legacy-prototype/` | Expo/React Native + Node (JSON file store) | 🗄 Archived. The earlier working prototype (login, home, admin screens) — kept for reference, no longer developed. |

## Why phased

This is a full production platform spanning two mobile apps, a web admin
panel, a REST API, a normalized database, and five external services
(Firebase Auth, FCM, Cloudinary, Google Maps, three payment gateways). That
is too much surface to build and verify in one pass, so it's being built
and checked phase by phase rather than claimed as a single "done" deliverable.

## Quick start (Phase 1 — backend only, today)

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:migrate
npm run seed
npm run dev
```

Needs a running PostgreSQL — either install it locally or, once `admin/`
exists, `docker compose up --build` from this directory starts Postgres +
the backend together (the `admin` service in `docker-compose.yml` is
commented out until Phase 2 exists).

## What needs you, not me

Some pieces need real accounts/credentials only you can create — I can't
fabricate them:

- **Firebase project** (Authentication + Cloud Messaging) — for Google
  Login, Phone/OTP login, and push notifications
- **Cloudinary account** — for chat photo / avatar uploads
- **Google Maps API key** — for pickup-address geocoding and rider navigation
- **bKash / Nagad / SSLCommerz merchant accounts** — each is a separate
  application process with that provider; Cash on Delivery works with zero
  configuration in the meantime

Until those are supplied, the backend runs in a clearly-labeled "dev mode"
for each (see `backend/README.md`'s status table) so the rest of the system
is testable without them.
