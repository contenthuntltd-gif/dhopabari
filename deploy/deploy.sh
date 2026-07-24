#!/usr/bin/env bash
# ============================================================
# Dhopa Bari — build the Flutter web app on the VPS and publish it.
#
# Run this ON the Contabo VPS, from the repo root, after a `git pull`.
# It builds a fresh release bundle and swaps it into the web root that
# nginx serves. Building on the Linux VPS avoids the Windows shader
# issue entirely.
#
# Usage:  bash deploy/deploy.sh
# ============================================================
set -euo pipefail

WEB_ROOT="/var/www/dhopabari"
APP_DIR="customer-app"

echo "▶ Pulling latest code…"
git pull --ff-only

echo "▶ Building Flutter web (release)…"
cd "$APP_DIR"
flutter pub get
# --pwa-strategy=none disables the Flutter service worker. Combined with the
# no-store headers in nginx, this means a browser NEVER serves a stale cached
# app — every deploy is picked up on the next normal refresh, no incognito or
# manual cache-clearing needed.
flutter build web --release --pwa-strategy=none
cd ..

echo "▶ Publishing to $WEB_ROOT…"
sudo mkdir -p "$WEB_ROOT"
sudo rsync -a --delete "$APP_DIR/build/web/" "$WEB_ROOT/"

echo "▶ Reloading nginx…"
sudo nginx -t
sudo systemctl reload nginx

echo "✓ Deployed. Visit your domain to verify."
