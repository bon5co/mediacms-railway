#!/bin/bash
# Railway boot for MediaCMS: derive the public URL and admin email, point nginx at the injected PORT, cap celery's process count, then
# hand over to upstream's own entrypoint (which chowns the tree, runs migrations, creates the admin user on the first start only, and
# starts nginx, gunicorn and celery under supervisord).
set -euo pipefail

: "${RAILWAY_PUBLIC_DOMAIN:?RAILWAY_PUBLIC_DOMAIN is not set (the service needs a public domain)}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is not set}"
: "${POSTGRES_HOST:?POSTGRES_HOST is not set}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}"
: "${REDIS_LOCATION:?REDIS_LOCATION is not set}"
: "${SECRET_KEY:?SECRET_KEY is not set}"

APP=/home/mediacms.io/mediacms
PORT="${PORT:-8080}"

export FRONTEND_HOST="https://${RAILWAY_PUBLIC_DOMAIN}"
export ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${RAILWAY_PUBLIC_DOMAIN}}"

# nginx listens on 80 in upstream's config; Railway's edge and healthcheck dial the injected PORT.
sed -i -E "s/^([[:space:]]*listen )[0-9]+( ?;)/\1${PORT}\2/" "$APP/deploy/docker/nginx_http_only.conf"
grep -q "listen ${PORT}" "$APP/deploy/docker/nginx_http_only.conf" || { echo "[railway] could not point nginx at port ${PORT}" >&2; exit 1; }

# Celery sizes its pool from the host's core count (long) or a fixed 2 x 10 (short); both oversubscribe a container.
SHORT_C="${CELERY_SHORT_CONCURRENCY:-2}"
LONG_C="${CELERY_LONG_CONCURRENCY:-2}"
sed -i -E "s/ -c[0-9]+ / -c${SHORT_C} /" "$APP/deploy/docker/supervisord/supervisord-celery_short.conf"
sed -i -E "/^command=.*celery multi start long1/ { /--concurrency|-c[0-9]/! s/ -Q long_tasks/ -c${LONG_C} -Q long_tasks/ }" "$APP/deploy/docker/supervisord/supervisord-celery_long.conf"

echo "[railway] port=${PORT} host=${FRONTEND_HOST} celery short=${SHORT_C} long=${LONG_C} media owner=$(stat -c %u:%g "$APP/media_files" 2>/dev/null || echo none)"
cd "$APP"
exec "$@"
