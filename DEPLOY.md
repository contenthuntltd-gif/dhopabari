# Dhopa Bari — Deployment Guide (GitHub + Contabo VPS)

## What actually gets deployed

Your app is a **Flutter web** front-end that talks **directly to Supabase**
(database + auth + edge functions, all in the cloud). So:

| Piece | Where it runs | You deploy it? |
|---|---|---|
| `customer-app/` (Flutter web — customer + admin + rider) | **Contabo VPS** (nginx serves static files) | ✅ yes, this guide |
| Supabase (Postgres, Auth, Storage) | Supabase cloud | already live — nothing to install |
| Edge Functions (`admin-create-user`, `admin-manage-user`) | Supabase cloud | ✅ once, via CLI (Part D) |
| `backend/` (old Node API) | — | ❌ the app no longer uses it — skip |

The VPS is basically a static file host. All the heavy lifting stays in Supabase.

---

## Part A — Push the code to GitHub

Run these from the project root (`E:\Dopa Bari`) on your PC:

```bash
git init
git add .
git status          # ⚠️ confirm backend/.env is NOT listed (it's gitignored)
git commit -m "Dhopa Bari — initial commit"
```

Create an **empty** repo on github.com (no README), then:

```bash
git branch -M main
git remote add origin https://github.com/<you>/dhopa-bari.git
git push -u origin main
```

> The `.gitignore` already protects secrets (`backend/.env`, keys, logs, build
> output). The Supabase **publishable** key inside the app is safe to commit —
> it only does what Row-Level-Security allows.

---

## Part B — Prepare the Contabo VPS (one time)

SSH in (Contabo emails you the IP + root password):

```bash
ssh root@YOUR_VPS_IP
```

Install nginx and the Flutter SDK (we build on the VPS — a clean Linux build,
no Windows shader problems):

```bash
apt update && apt upgrade -y
apt install -y nginx git curl unzip xz-utils

# Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter --version        # first run downloads the engine; give it a minute
```

---

## Part C — Build & serve the app

```bash
# Clone your repo
git clone https://github.com/<you>/dhopa-bari.git /opt/dhopa-bari
cd /opt/dhopa-bari

# Build + publish (the helper script does all of it)
bash deploy/deploy.sh
```

`deploy.sh` builds `customer-app` and copies `build/web` into
`/var/www/dhopabari`. Now wire up nginx:

```bash
# Edit the domain name first:
nano deploy/nginx-dhopabari.conf      # set server_name to your domain

sudo cp deploy/nginx-dhopabari.conf /etc/nginx/sites-available/dhopabari
sudo ln -s /etc/nginx/sites-available/dhopabari /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default   # drop the placeholder site
sudo nginx -t && sudo systemctl reload nginx
```

Visit `http://YOUR_VPS_IP` — the app should load.

### Domain + HTTPS

1. In your domain registrar, add an **A record** pointing `dhopabari.com`
   (and `www`) to your VPS IP.
2. Once DNS resolves, enable free HTTPS:

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d dhopabari.com -d www.dhopabari.com
```

Certbot edits the nginx config, installs the certificate, and auto-renews it.

---

## Part D — Supabase production settings (important)

1. **Auth URLs** — Supabase Dashboard → *Authentication → URL Configuration*:
   - **Site URL**: `https://dhopabari.com`
   - **Redirect URLs**: add `https://dhopabari.com` (and `https://www.dhopabari.com`)

   Without this, Google login and email confirmations break in production.

2. **Edge Functions** (needed only for creating users *from* the admin panel).
   Install the Supabase CLI on your PC, then:

```bash
supabase login
supabase link --project-ref stxzqmrnezedphysmczq
supabase functions deploy admin-create-user
supabase functions deploy admin-manage-user
```

   `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are
   injected into functions automatically — no secrets to set by hand.

3. **Migrations** — you already ran `supabase/APPLY_ALL.sql` in the SQL
   editor, so the database is ready. (Re-running it is safe if unsure.)

---

## Updating later (every new change)

On your PC:

```bash
git add . && git commit -m "…" && git push
```

On the VPS:

```bash
cd /opt/dhopa-bari && bash deploy/deploy.sh
```

That's the whole update loop. (Optional next step: a GitHub Actions workflow
that SSHes in and runs `deploy.sh` automatically on every push — ask when you
want it.)

---

## Quick reference

| Thing | Value |
|---|---|
| Web root nginx serves | `/var/www/dhopabari` |
| Build command | `flutter build web --release` (in `customer-app/`) |
| Supabase project ref | `stxzqmrnezedphysmczq` |
| Demo admin login | `01700000001` / `admin123` (⚠️ change before real launch) |
