FROM php:8.3-fpm-bookworm

LABEL org.opencontainers.image.title="Pterodactyl WordPress"
LABEL org.opencontainers.image.description="WordPress runtime image for Pterodactyl with PHP-FPM, Nginx and WP-CLI"
LABEL org.opencontainers.image.source="https://github.com/wienni112/pterodactyl-wordpress"

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    curl \
    unzip \
    jq \
    mariadb-client \
    ca-certificates \
    bash \
    less \
    nano \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli pdo pdo_mysql exif opcache

RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p /home/container \
    && chown -R www-data:www-data /home/container

WORKDIR /home/container

EXPOSE 8080

CMD ["/bin/bash"]