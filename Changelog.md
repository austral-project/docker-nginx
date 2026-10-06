Changelog
=========

### Version Nginx 1.20 (2026-10-06)

**Non-root support**
* Add support for any UID/GID (e.g. Swarm `user: "3001:3001"`); the container no longer needs root
* Add rendering of the configuration at start-up into `/tmp/nginx`, writable by any user (temporary files and pid included)
* Add `gettext` (`envsubst`) to the image
* Add `LISTEN_PORT` (default 80)

**Configuration overrides**
* Add `/overrides/website.conf` and `/overrides/nginx.conf` to replace a whole file
* Add `/overrides/server.d/*.conf` (inside the server block) and `/overrides/conf.d/*.conf` (http level) as drop-ins
* Update `website.custom`: still supported, replaced by `/overrides/website.conf`
* Add env vars `MODE`, `PHP_MODE`, `FASTCGI_PASS`, `FASTCGI_READ_TIMEOUT`, `CLIENT_MAX_BODY_SIZE`, `CACHE_STATIC_MAX_AGE`, `CORS_ALLOW_ORIGIN`, `X_FRAME_OPTIONS`, `REAL_IP_FROM`, `WORKER_PROCESSES`, `ERROR_LOG_LEVEL`, `ACCESS_LOG_ENABLED`, `BROTLI`
* Update `HTTPS`: accepts `auto` (deduced from `X-Forwarded-Proto`)
* Update `ALONE` and `FASTCGI_PASS=alone`: replaced by `MODE=static` (old values still work)
* Update `FASTCGI_PASS`: now the PHP-FPM address (`host:port`); `FASTCGI_PASS_VALUE` still works

**Static mode**
* Add `MODE=static` (static site / SPA, unknown routes return `index.html`) and `PHP_MODE`; this image only had the PHP mode before

**Compatibility**
* Keep `APP_DEBUG` (default `false`) and `APP_ENV` (default `prod`): still passed to PHP as FastCGI parameters
* Keep `HTTPS` default to `off` (as in the previous 1.20 image)
* Delete log files in `var/docker-log/nginx` and the `chown` of `var`: logs go to `docker logs`

**Fixes**
* Fix syntax error in `website.alone` (`location location`)
* Fix empty directive generated with `FASTCGI_PASS=test`
* Fix security headers lost on static files (`add_header` is not inherited)
* Fix invalid CORS combination (`Allow-Origin: *` with `Allow-Credentials: true`): credentials header removed
* Delete `if (-f $request_filename)` in the PHP location

**Cache and security**
* Update cache: 1 year + `immutable` only for files with a hash in their name, `CACHE_STATIC_MAX_AGE` for other static files, `no-cache` for HTML
* Add hidden files protection (404), except `/.well-known/`
* Add script execution block in `uploads` directories
* Add `PHP_MODE=front` (only the front controller is executed) and `classic` (default, any existing `.php`)
* Add `PHP_FRONT_SCRIPT` (default `index.php`), `PHP_ALLOWED_SCRIPTS` (extra scripts reachable by URL in `front` mode) and `PHP_ALLOWED_SCRIPTS_IPS` (IP restriction for those scripts)
* Update PHP location: only existing `.php` files are executed (`try_files $fastcgi_script_name =404`)
* Add `Referrer-Policy` header; delete obsolete `X-XSS-Protection`, `ssl_*` settings (TLS 1.0/1.1 included) and `gzip_disable msie6`

**Error pages**
* Add styled error pages (400, 401, 403, 404, 405, 408, 413, 414, 429, 500, 501, 502, 503, 504), in French or English (`ERROR_LANG`)
* Add `/overrides/errors/<code>.html`, `/overrides/errors/error.html` (generic template) and assets served under `/__errors/`
* Add `ERROR_PAGES` and `INTERCEPT_PHP_ERRORS`; errors returned by the PHP application are untouched by default

**Runtime**
* Add `/healthz` endpoint; healthcheck uses it instead of `nc`
* Add Docker DNS resolution of the PHP upstream at request time: nginx starts even if PHP is not up yet
* Add real client IP behind Traefik (`real_ip_header X-Forwarded-For`)
* Add Brotli compression when the module is installed
* Add `nginx -t` before start-up, with a clear error message
* Update `client_max_body_size` default from 10G to 64M, and `fastcgi_read_timeout` to 300s (aligned with the PHP image)
* Add `WORKER_RLIMIT_NOFILE` and `WORKER_CONNECTIONS`, computed from the container limits (no more "worker_connections exceed open file resource limit" warning)
* Update default command to `nginx` (expanded by the entrypoint with the rendered configuration)

### Version Nginx 1.20 (2022-07-06)
* Create Dockerfile
* Create Github repository
* Create an image in the Docker hub