#!/bin/bash

set -euo pipefail

echo "========================================"
echo "Starting WordPress Container"
echo "========================================"

cd /home/container

# Standardwerte
PHP_FPM_PID=""

# WordPress nur beim ersten Start installieren
if [ ! -f wp-config.php ]; then

    echo "No wp-config.php found"
    echo "Installing WordPress..."

    wp core download --allow-root

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

echo "Starting Nginx..."

exec nginx -g "daemon off;"