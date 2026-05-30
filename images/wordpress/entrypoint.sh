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

echo "Starting PHP-FPM..."

php-fpm -D

echo "Starting Nginx..."

cat > /tmp/default.conf <<EOF
server {
    listen ${SERVER_PORT:-8080};
    server_name _;

    root /home/container;
    index index.php index.html;

    client_max_body_size 128M;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;

        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;

        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME \$fastcgi_script_name;

        fastcgi_read_timeout 300;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|webp|svg|css|js|woff|woff2|ttf|eot)$ {
        expires 30d;
        access_log off;
        try_files \$uri =404;
    }

    location ~ /\. {
        deny all;
    }

    location ~* /(wp-config\.php|readme\.html|license\.txt)$ {
        deny all;
    }

    location = /xmlrpc.php {
        deny all;
    }
}
EOF

echo "Starting Nginx on port ${SERVER_PORT:-8080}..."

exec nginx -c /tmp/default.conf -g "daemon off;"