# MediaCMS wrapper for Railway. Upstream's compose runs migrations, web, celery_beat and celery_worker as four containers from one
# image over shared volumes, which Railway cannot do (a volume attaches to one service). The image's own defaults already run
# everything in one container under supervisord (nginx, gunicorn, celery short and long workers, celery beat, migrations), so this
# wrapper keeps that and adds what Railway needs: nginx on the injected PORT, the database and Redis wired from variables, the
# admin login from ADMIN_PASSWORD, self-registration closed (upstream leaves it open), HTTPS-behind-proxy settings, and a cap on
# celery's process count (celery sizes its pool from the HOST's core count).
# upstream: mediacms-io/mediacms
# mediacms/mediacms publishes only a rolling `latest` tag; this digest is the image built from release v9.6.1 (2026-11-19, the newest
# release at build time, checked against the GitHub releases API and Docker Hub on 2026-11-23).
FROM mediacms/mediacms:latest@sha256:c7cb3abdf8086accadc1c0d13f08b8943ae13967259fe99c3f0180467a13ab7d

# Baked so the deploy form stays empty: a literal template variable publishes as a blank required field.
ENV ADMIN_USER=admin

# entrypoint.sh copies deploy/docker/local_settings.py over cms/local_settings.py on every start, and cms/settings.py imports it last,
# so these lines override the defaults.
RUN cat >> /home/mediacms.io/mediacms/deploy/docker/local_settings.py <<'PY'

# --- Railway wrapper ---
# Self-registration is open by default upstream; the admin login comes from ADMIN_PASSWORD and the admin invites everyone else.
USERS_CAN_SELF_REGISTER = False
REGISTER_ALLOWED = False
# TLS ends at Railway's edge; nginx passes X-Forwarded-Proto on, so Django must trust it or every login POST fails the CSRF origin check.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
CSRF_TRUSTED_ORIGINS = [FRONTEND_HOST]
PY

COPY railway-boot.sh /railway-boot.sh
RUN chmod 0755 /railway-boot.sh

EXPOSE 8080
ENTRYPOINT ["/railway-boot.sh"]
CMD ["./deploy/docker/entrypoint.sh", "./deploy/docker/start.sh"]
