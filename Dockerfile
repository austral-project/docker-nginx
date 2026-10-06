FROM australproject/alpine:3.17
LABEL maintainer="Matthieu Beurel <matthieu@austral.dev>"

# Init Docker (brotli is optional: the entrypoint enables it only when the module is installed)
RUN apk update && apk upgrade \
        && apk add --no-cache nginx gettext \
        && (apk add --no-cache nginx-mod-http-brotli || echo "WARN: brotli module not available") \
        && rm -rf /var/cache/apk/*

# Config templates (rendered at start-up by the entrypoint into /tmp/nginx)
COPY config/nginx.conf config/website.conf config/website.alone /usr/local/share/nginx-templates/
COPY config/snippets/ /usr/local/share/nginx-templates/snippets/
COPY config/errors/ /usr/local/share/nginx-templates/errors/
RUN chmod -R a+rX /usr/local/share/nginx-templates

COPY config/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 0755 /docker-entrypoint.sh

# Any UID must be able to write here (rendered config, temporary files)
RUN mkdir -p /tmp/nginx /home/www-data/website \
    && chmod 1777 /tmp/nginx

ENV NGINX_RUN_DIR=/tmp/nginx
WORKDIR /home/www-data/website

#  Init Entrypoint, CMD
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${LISTEN_PORT:-80}/healthz" || exit 1
CMD ["nginx"]
