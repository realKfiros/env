#!/usr/bin/env bash

source "$(dirname "$0")/dotenv.sh"

set -e

# ===== CONFIG =====
CONTAINER_NAME="$DB_CONTAINER_NAME"
MYSQL_USER="root"
MYSQL_PASSWORD="$DB_ROOT_PASSWORD"
MYSQL_PORT=$DB_PORT

# ===== CHECK INPUT =====
if [ -z "$1" ]; then
  echo "Usage: ./import-sql.sh <file.sql>"
  exit 1
fi

SQL_FILE="$1"

if [ ! -f "$SQL_FILE" ]; then
  echo "File not found: $SQL_FILE"
  exit 1
fi

# ===== DATABASE NAME =====
BASENAME=$(basename "$SQL_FILE")
DB_NAME="${BASENAME%.*}"

echo "➡️ Database name: $DB_NAME"

# ===== COPY FILE TO CONTAINER =====
echo "📦 Copying SQL file to container..."
docker cp "$SQL_FILE" "$CONTAINER_NAME:/tmp/$BASENAME"

# ===== CREATE DATABASE =====
echo "🛠 Creating database..."
docker exec -i "$CONTAINER_NAME" \
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

# ===== IMPORT =====
echo "⬇️ Importing SQL..."
docker exec -i "$CONTAINER_NAME" \
  mysql -v -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DB_NAME" \
  < "$SQL_FILE"

echo "✅ Done!"