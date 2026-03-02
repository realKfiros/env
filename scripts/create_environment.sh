#!/usr/bin/env bash

BASEDIR=$(dirname "$0")

set -e

cat <<EOF > "$BASEDIR"/../.env
WEB_CONTAINER_NAME=web
DB_CONTAINER_NAME=db
DB_ROOT_PASSWORD=12345678
DB_PORT=3306
EOF

echo "✅ Environment file created at .env"