# mediacms-railway

Wrapper image that lets [MediaCMS](https://github.com/mediacms-io/mediacms) (AGPL-3.0) run as a Railway template.

`ghcr.io/bon5co/mediacms-railway` wraps the official `mediacms/mediacms` image (release v9.6.1). Upstream's compose runs four containers
(migrations, web, celery beat, celery worker) from that image over shared volumes; a Railway volume attaches to one service, so this
image keeps the image's own single-container mode (nginx, gunicorn, celery and migrations under supervisord). It points nginx at
Railway's injected `PORT`, caps celery's process count, creates the admin login from `ADMIN_PASSWORD`, and turns public
self-registration off, which upstream leaves open.

The Railway template that uses it is published from the `bon5co` workspace; this repository holds only the image.
