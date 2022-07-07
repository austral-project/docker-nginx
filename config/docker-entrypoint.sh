#!/usr/bin/env sh
set -eu

if [ ! -d "/home/www-data/website/var/docker-log/nginx" ]
then
  mkdir -p /home/www-data/website/var/docker-log/nginx
fi
chown -R www-data:www-data /home/www-data/website/var

#### Init var APP_DEBUG if not defined or is empty
if [[ -z "${APP_DEBUG+x}" ]]; then
  APP_DEBUG="false"
fi

#### Init var APP_ENV if not defined or is empty
if [[ -z "${APP_ENV+x}" ]]; then
  APP_ENV="prod"
fi

#### Init var PUBLIC_DIR if not defined or is empty
if [[ -z "${PUBLIC_DIR+x}" ]]; then
  PUBLIC_DIR="public"
fi

#### Init var FASTCGI_PASS if not defined or is empty
if [[ -z "${HTTPS+x}" ]]; then
  HTTPS="php"
fi

#### Init var FASTCGI_PASS if not defined or is empty
if [[ -z "${FASTCGI_PASS+x}" ]]; then
  FASTCGI_PASS="php"
fi

if [[ "${FASTCGI_PASS}" = "test" ]]; then
  FASTCGI_PASS_KEY=""
  FASTCGI_PASS_VALUE=""
else
  FASTCGI_PASS_KEY="fastcgi_pass"
  FASTCGI_PASS_VALUE="php:9900;"
fi

echo "App Debug : ${APP_DEBUG}"
echo "App environnement : ${APP_ENV}"
echo "Public dir : ${PUBLIC_DIR}"
echo "Fastcgi_pass : ${FASTCGI_PASS_KEY} ${FASTCGI_PASS_VALUE}"

export APP_ENV
export APP_DEBUG
export FASTCGI_PASS_KEY
export FASTCGI_PASS_VALUE

envsubst '$FASTCGI_PASS_KEY,$FASTCGI_PASS_VALUE,$APP_DEBUG,$APP_ENV,$PUBLIC_DIR' < /etc/nginx/sites-available/website.template > /etc/nginx/sites-available/website
exec "$@"