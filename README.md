# Austral Docker Nginx

[![License](https://img.shields.io/github/license/austral-project/docker-nginx)](https://img.shields.io/github/license/austral-project/docker-nginx)
[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/australproject/nginx/1.28)](https://img.shields.io/docker/v/australproject/nginx/1.28)
[![Docker Automated build](https://img.shields.io/docker/automated/australproject/nginx)](https://img.shields.io/docker/automated/australproject/alpine)
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/australproject/nginx)](https://img.shields.io/docker/cloud/build/australproject/nginx)
[![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/australproject/nginx)](https://img.shields.io/docker/image-size/australproject/nginx)

View repository for the base image Alpine 3.23 : [Docker Hub](https://hub.docker.com/r/australproject/alpine/) or [Gitub](https://github.com/austral-project/docker-alpine)

## Versions

* Alpine: 3.23
* Nginx: 1.28
* Brotli module: installed when available (enabled automatically)

## Modes

| `MODE` | Use |
|---|---|
| `php` (default) | Static files + PHP-FPM (`FASTCGI_PASS`), for Symfony, WordPress, ... |
| `static` | Static site / SPA: unknown routes return `index.html` |

With `MODE=php`, `PHP_MODE` defines which PHP files can be executed:

| `PHP_MODE` | Behaviour |
|---|---|
| `classic` (default) | Any existing `.php` file (WordPress, legacy sites). Script execution is always blocked in `uploads/` directories |
| `front` | Only the front controller (`index.php`) and the scripts you allow (see below). Every other `.php` URL returns 404 |

**Allowed scripts (`PHP_MODE=front`)**: some projects have extra scripts reachable by URL, for example a `yipikai.php` that switches the site to dev mode. List them explicitly:

```yaml
environment:
  - PHP_MODE=front
  - PHP_ALLOWED_SCRIPTS=yipikai.php            # comma separated, file names at the root of the public directory
  - PHP_ALLOWED_SCRIPTS_IPS=203.0.113.10,198.51.100.0/24   # optional: only these IPs can reach them
```

The front controller itself (`PHP_FRONT_SCRIPT`, default `index.php`) is never reachable directly, only through the application routes. With `PHP_ALLOWED_SCRIPTS_IPS`, other visitors get a 403 (the real client IP is used, see `REAL_IP_FROM`).

Previous settings still work: `ALONE=true` or `FASTCGI_PASS=alone` select `MODE=static`, `FASTCGI_PASS_VALUE` is used as `FASTCGI_PASS`, and a mounted `/etc/nginx/sites-available/website.custom` still replaces the site configuration.

## Running as any user (non-root)

The image runs as root **or** as any UID/GID, for example with Docker Swarm:

```yaml
services:
  nginx:
    image: australproject/nginx:1.28
    user: "3001:3001"
    volumes:
      - /home/owner/websites/example.com:/home/www-data/website:ro
```

The configuration is rendered at start-up into `/tmp/nginx` (writable by any user). Use the same UID/GID as the PHP service so both read the same files. As root, workers run as `www-data` (legacy behaviour).

Listening on port 80 as non-root works on current Docker versions. If it fails with `Permission denied`, set `LISTEN_PORT=8080` and update the Traefik port label.

Quick test:

```bash
docker run --rm -u 3001:3001 -e MODE=static -p 8080:80 australproject/nginx:1.28
curl -i http://127.0.0.1:8080/healthz
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `MODE` | `php` | `php` or `static` |
| `PHP_MODE` | `classic` | `classic` or `front` |
| `PHP_FRONT_SCRIPT` | `index.php` | Front controller (`front` mode: internal only; also used as fallback in `classic` mode) |
| `PHP_ALLOWED_SCRIPTS` | empty | `front` mode: other scripts reachable by URL (comma separated) |
| `PHP_ALLOWED_SCRIPTS_IPS` | empty | `front` mode: IPs/CIDRs allowed to reach those scripts (empty = everyone) |
| `PUBLIC_DIR` | `public` | Public directory, relative to `/home/www-data/website` |
| `LISTEN_PORT` | `80` | Listening port |
| `FASTCGI_PASS` | `php:9900` | PHP-FPM address (`host` or `host:port`). Resolved at request time: nginx starts even if PHP is not up yet |
| `FASTCGI_READ_TIMEOUT` | `300s` | PHP timeout (keep it equal to `FPM_REQUEST_TERMINATE_TIMEOUT`) |
| `HTTPS` | `on` | Value of the PHP `HTTPS` variable: `on`, `off` or `auto` (from `X-Forwarded-Proto`) |
| `CLIENT_MAX_BODY_SIZE` | `64M` | Maximum upload size (keep it aligned with `PHP_POST_MAX_SIZE`) |
| `CACHE_STATIC_MAX_AGE` | `3600` | Browser cache of static files, in seconds |
| `CORS_ALLOW_ORIGIN` | `*` | `Access-Control-Allow-Origin` of static files. Empty to disable |
| `X_FRAME_OPTIONS` | `DENY` | `X-Frame-Options` header. Empty to disable |
| `REAL_IP_FROM` | `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` | Trusted proxies (comma separated) for the real client IP. Empty to disable |
| `WORKER_PROCESSES` | `auto` | Nginx workers |
| `WORKER_RLIMIT_NOFILE` | hard limit of the container (max 16384) | Open files per worker |
| `WORKER_CONNECTIONS` | half of `WORKER_RLIMIT_NOFILE` (max 4096) | Connections per worker |
| `ERROR_LOG_LEVEL` | `warn` | Nginx error log level |
| `ACCESS_LOG_ENABLED` | `1` | `0` disables the access log |
| `BROTLI` | `auto` | `auto`, `on` or `off` |

## Cache and headers

* Static files whose name contains a hash (`app.3f2a9c1b.js`, `app-3f2a9c1b.css`): `public, max-age=31536000, immutable`
* Other static files: `public, max-age=CACHE_STATIC_MAX_AGE`
* HTML files: `no-cache` (always revalidated, so a new deployment is seen immediately)
* Static files served directly also carry the header `Austral: Direct-Link`
* Security headers on every response: `X-Frame-Options`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`
* Hidden files (`.git`, `.env`, `.htaccess`, ...) return 404, except `/.well-known/`
* A missing static file is handled by the application (`MODE=php`), so dynamic `robots.txt` or generated images keep working

Gzip is always enabled, and Brotli when the module is installed.

## Overriding the configuration

Mount a directory on `/overrides` (read-only is fine):

| Path in `/overrides` | Effect |
|---|---|
| `website.conf` | Replaces the whole site configuration (copied as is, no variable substitution) |
| `nginx.conf` | Replaces the whole `nginx.conf` |
| `server.d/*.conf` | Added **inside** the `server` block (extra `location`, redirects, ...) |
| `conf.d/*.conf` | Added at `http` level (extra maps, limits, other servers, ...) |

```nginx
# /overrides/server.d/redirect.conf
location = /old-page { return 301 /new-page; }
```

## Error pages

Errors generated by nginx (403, 404 on static sites, 413 upload too large, 502/503/504 when PHP is down or too slow...) use styled pages: `400 401 403 404 405 408 413 414 429 500 501 502 503 504`. Errors returned by the PHP application itself (the Symfony or WordPress 404/500 pages) are left untouched.

| Variable | Default | Description |
|---|---|---|
| `ERROR_PAGES` | `on` | `off` restores the default nginx error pages |
| `ERROR_LANG` | `fr` | Language of the default pages: `fr` or `en` |
| `INTERCEPT_PHP_ERRORS` | `off` | `on` also replaces the error pages returned by PHP |

To use your own pages, mount a directory on `/overrides/errors`:

| File in `/overrides/errors` | Effect |
|---|---|
| `404.html`, `502.html`, ... | Page used as is for this status code |
| `error.html` | Generic template for every code that has no own file. Placeholders: `${ERROR_CODE}`, `${ERROR_TITLE}`, `${ERROR_MESSAGE}`, `${ERROR_HOME_LABEL}` |
| anything else (`style.css`, images, fonts) | Served under `/__errors/`, e.g. `<link rel="stylesheet" href="/__errors/style.css">` |

```yaml
volumes:
  - ./error-pages:/overrides/errors:ro
```

The HTTP status code is kept (a 404 page is still sent with a 404 status). Use absolute paths starting with `/__errors/` for your assets.

## Health check

`GET /healthz` returns `200 ok` and is not logged. The image healthcheck uses it.

## Logs

Access and error logs go to the container output (`docker logs`). Behind Traefik, the real client IP is read from `X-Forwarded-For` (`REAL_IP_FROM`).

## Commit Messages

The commit message must follow the [Conventional Commits specification](https://www.conventionalcommits.org/).
The following types are allowed:

* `update`: Update
* `fix`: Bug fix
* `feat`: New feature
* `docs`: Change in the documentation
* `spec`: Spec change
* `test`: Test-related change
* `perf`: Performance optimization

Examples:

    update : Something

    fix: Fix something

    feat: Introduce X

    docs: Add docs for X

    spec: Z disambiguation

## License and Copyright
See [License](https://austral.dev/en/license)

## Credits
Created by [Matthieu Beurel](https://www.mbeurel.com). Sponsored by [Yipikai Studio](https://yipikai.studio).