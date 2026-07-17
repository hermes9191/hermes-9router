#!/bin/bash
# =============================================================
#  9Router — Railway entrypoint
# =============================================================
set -e

echo "══════════════════════════════════════════"
echo "  9Router — Railway Start"
echo "══════════════════════════════════════════"
echo "PORT=${PORT:-20128}"
echo "Starting at: $(date)"

# Railway injects $PORT; 9Router listens on this
# If PORT is set, override the default 20128
export PORT="${PORT:-20128}"
export HOSTNAME="${HOSTNAME:-0.0.0.0}"
export NODE_ENV="${NODE_ENV:-production}"
export DATA_DIR="${DATA_DIR:-/app/data}"

# Ensure data directory exists
mkdir -p "$DATA_DIR" /app/data-home
chown -R node:node "$DATA_DIR" /app/data-home 2>/dev/null || true

# Link home dir for MITM / runtime files
ln -sf /app/data-home /root/.9router 2>/dev/null || true

# ---- Nginx (optional reverse-proxy for Railway) ----
# If you want nginx in front of 9Router on Railway, uncomment below.
# Otherwise 9Router listens directly on $PORT.
# NGINX_PORT="${PORT}"
# envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
# nginx -t && nginx -g "daemon off;" &

# ---- Start 9Router ----
echo "[1] Starting 9Router on port $PORT..."
cd /app
exec node custom-server.js
