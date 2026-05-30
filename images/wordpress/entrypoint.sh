#!/bin/bash

set -euo pipefail

echo "========================================"
echo "Starting WordPress Container"
echo "========================================"

cd /home/container

# Datenbank Host/Port aufteilen
DB_PORT="3306"

if [[ "${DB_HOST}" == *":"* ]]; then
    DB_PORT="${DB_HOST##*:}"
    DB_HOST_ONLY="${DB_HOST%%:*}"
else
    DB_HOST_ONLY="${DB_HOST}"
fi

# Standardwerte
PHP_FPM_PID=""

# WordPress nur beim ersten Start installieren
if [ ! -f wp-config.php ]; then

    echo "No wp-config.php found"
    echo "Installing WordPress..."

    if [ ! -f index.php ] || [ ! -d wp-admin ]; then
        echo "Downloading WordPress core..."
        wp core download --allow-root --force
    else
        echo "WordPress core files already exist"
    fi

    echo "Waiting for database..."

    until mysql \
    -h"${DB_HOST_ONLY}" \
    -P"${DB_PORT}" \
    -u"${DB_USER}" \
    -p"${DB_PASS}" \
    -e "SELECT 1" >/dev/null 2>&1
    do
    sleep 5
    done

    echo "Database is available"

    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASS}" \
        --dbhost="${DB_HOST}" \
        --skip-check \
        --allow-root

    wp core install \
        --url="${SITE_URL}" \
        --title="${SITE_TITLE}" \
        --admin_user="${ADMIN_USER}" \
        --admin_password="${ADMIN_PASS}" \
        --admin_email="${ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "WordPress installation completed"

else

    echo "Existing WordPress installation detected"

fi

# Dateirechte setzen
chown -R www-data:www-data /home/container

echo "Starting PHP-FPM..."

php-fpm -D

echo "Configuring Nginx listen port: ${SERVER_PORT:-8080}"
sed -i "s/listen 8080;/listen ${SERVER_PORT:-8080};/g" /etc/nginx/conf.d/default.conf

echo "Starting Nginx..."

exec nginx -g "daemon off;"