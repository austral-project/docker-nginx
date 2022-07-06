FROM australproject/alpine:3.15
LABEL maintainer="Matthieu Beurel <matthieu@austral.dev>"

#  Install necessary packages for Nginx
RUN apk add --update --no-cache nginx

RUN rm -rf /var/cache/apk/*

# Init Nginx config
COPY config/nginx.conf /etc/nginx/nginx.conf
RUN mkdir /etc/nginx/sites-enabled

COPY config/website.conf /etc/nginx/sites-available/website.template
COPY config/website.conf /etc/nginx/sites-available/website

RUN ln -s /etc/nginx/sites-available/website /etc/nginx/sites-enabled/default
RUN mkdir -p /var/lib/nginx/tmp /var/log/nginx \
    && chown -R www-data:www-data /var/lib/nginx /var/log/nginx \
    && chmod -R 755 /var/lib/nginx /var/log/nginx

COPY config/docker-entrypoint.sh /
RUN chmod -R 755 /docker-entrypoint.sh

#  Init Workdir, Entrypoint, CMD
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80
STOPSIGNAL SIGQUIT

WORKDIR /home/www-data/website
CMD ["nginx", "-g", "daemon off;"]