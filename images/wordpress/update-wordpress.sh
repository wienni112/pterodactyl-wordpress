#!/bin/bash
set -euo pipefail

cd /home/container

wp core update --allow-root
wp plugin update --all --allow-root
wp theme update --all --allow-root
wp core language update --allow-root