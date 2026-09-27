# ============================================================
# Dhopa Bari — build the Flutter web app and serve it.
#
# This is the Coolify/Docker equivalent of deploy/deploy.sh. That script
# installs Flutter and nginx directly on the VPS; this builds the same bundle
# inside a container instead, which matters because Coolify's Traefik already
# owns ports 80 and 443 on the host — a second nginx there would collide.
#
# Building on Linux (rather than Windows) also avoids the shader issue the
# deploy script mentions.
#
# No build arguments are needed. The Supabase URL and publishable key have
# defaults compiled into lib/services/supabase_config.dart and are safe in a
# client: Row Level Security decides what that key can actually do.
# ============================================================

# ---------- build ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy the manifests first so `pub get` is cached and only re-runs when the
# dependencies actually change, not on every source edit.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# --pwa-strategy=none disables the Flutter service worker. Together with the
# no-store headers below it means a browser can never hold on to a stale app:
# every deploy is picked up on the next ordinary refresh, with no incognito
# window and no cache clearing.
RUN flutter build web --release --pwa-strategy=none

# ---------- serve ----------
FROM nginx:1.27-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Traefik terminates TLS and talks to this container over plain HTTP on 80.
EXPOSE 80

# Fail the container if nginx stops answering, so Coolify can restart it
# rather than leaving a dead site serving nothing.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
