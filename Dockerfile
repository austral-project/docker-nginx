# Dockerfile.nginx
FROM australproject/alpine:3.23
LABEL maintainer="Matthieu Beurel <matthieu@austral.dev>"

#  Init Docker
RUN apk update && apk upgrade \
        && apk add --no-cache nginx \
        && mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled \
        && rm -rf /var/cache/apk/* \
        && mkdir -p /var/lib/nginx/tmp \
        && chown -R www-data:www-data /var/lib/nginx \
        && chmod -R 755 /var/lib/nginx

# Init Nginx config
COPY config/nginx.conf /etc/nginx/nginx.conf

# Virtual hosts
COPY config/website.conf /etc/nginx/sites-available/website.template
COPY config/website.alone /etc/nginx/sites-available/website.alone
COPY config/website.conf /etc/nginx/sites-available/website
RUN ln -s /etc/nginx/sites-available/website /etc/nginx/sites-enabled/default

COPY config/docker-entrypoint.sh /
RUN chmod -R 755 /docker-entrypoint.sh

WORKDIR /home/www-data/website

#  Init Workdir, Entrypoint, CMD
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]