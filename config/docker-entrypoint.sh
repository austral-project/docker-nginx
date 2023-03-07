#!/usr/bin/env sh
set -eu

if [ ! -d "/home/www-data/website/var/docker-log/nginx" ]
then
  mkdir -p /home/www-data/website/var/docker-log/nginx
fi
chown -R www-data:www-data /home/www-data/website/var

#### Init var PUBLIC_DIR if not defined or is empty
if [ -z "${PUBLIC_DIR+x}" ]; then
  PUBLIC_DIR="public"
fi

#### Init var HTTPS if not defined or is empty
if [ -z "${HTTPS+x}" ]; then
  HTTPS="on"
fi

#### Init var FASTCGI_PASS if not defined or is empty
if [ -z "${FASTCGI_PASS+x}" ]; then
  FASTCGI_PASS="php"
fi

if [ "${FASTCGI_PASS}" = "test" ]; then
  FASTCGI_PASS_KEY=""
  FASTCGI_PASS_VALUE=""
else
  FASTCGI_PASS_KEY="fastcgi_pass"
  FASTCGI_PASS_VALUE="php:9900;"
fi

echo "Public dir : ${PUBLIC_DIR}"
echo "HTTPS : ${HTTPS}"
echo "Fastcgi_pass : ${FASTCGI_PASS_KEY} ${FASTCGI_PASS_VALUE}"

export FASTCGI_PASS_KEY
export FASTCGI_PASS_VALUE
export HTTPS
export PUBLIC_DIR

if test -f /etc/nginx/sites-available/website
then
  echo "Website nginx config exist"
else
  echo "Generate Website nginx config"
  envsubst '$FASTCGI_PASS_KEY,$FASTCGI_PASS_VALUE,$HTTPS,$PUBLIC_DIR' < /etc/nginx/sites-available/website.template > /etc/nginx/sites-available/website
fi

exec "$@"