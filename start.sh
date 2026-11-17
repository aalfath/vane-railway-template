#!/bin/bash
# Starts SearXNG (127.0.0.1:8888), Vane (127.0.0.1:3000) and Caddy (:$PORT, login in front).
# If any of the three exits, the container exits so Railway's restart policy brings it back.
set -euo pipefail

export PORT="${PORT:-8080}"
export VANE_USERNAME="${VANE_USERNAME:-admin}"
if [ -z "${VANE_PASSWORD:-}" ] || [ "${#VANE_PASSWORD}" -lt 12 ]; then
  echo "VANE_PASSWORD must be set (at least 12 characters). Refusing to start without a login." >&2
  exit 1
fi
case "$PORT" in 3000|8888) echo "PORT $PORT is used internally; pick another (default 8080)." >&2; exit 1 ;; esac

VANE_PASSWORD_HASH="$(caddy hash-password --plaintext "$VANE_PASSWORD")"
export VANE_PASSWORD_HASH

# SearXNG's secret only signs its own cookies and image-proxy URLs: a fresh one per boot is fine.
SEARXNG_SECRET="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"

mkdir -p /home/vane/data/uploads

sudo -H -u searxng env SEARXNG_SECRET="$SEARXNG_SECRET" SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml \
  bash -c 'cd /usr/local/searxng/searxng-src && FLASK_APP=searx/webapp.py exec /usr/local/searxng/searx-pyenv/bin/python -m flask run --host=127.0.0.1 --port=8888' &
SEARXNG_PID=$!

for _ in $(seq 1 60); do
  curl -fs -o /dev/null http://127.0.0.1:8888/healthz && break
  sleep 1
done

cd /home/vane
env -u VANE_PASSWORD -u VANE_PASSWORD_HASH HOSTNAME=127.0.0.1 PORT=3000 node server.js &
VANE_PID=$!

env -u VANE_PASSWORD caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill -TERM $SEARXNG_PID $VANE_PID $CADDY_PID 2>/dev/null; wait; exit 0' TERM INT

set +e
wait -n $SEARXNG_PID $VANE_PID $CADDY_PID
code=$?
echo "A process exited (code $code); stopping the container so Railway restarts it." >&2
kill -TERM $SEARXNG_PID $VANE_PID $CADDY_PID 2>/dev/null
wait
exit "${code:-1}"
