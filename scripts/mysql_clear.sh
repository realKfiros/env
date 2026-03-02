#!/usr/bin/env bash

source "$(dirname "$0")/dotenv.sh"

set -e

set -euo pipefail

# ---------------------------
# Config
# ---------------------------
CONTAINER_NAME="$DB_CONTAINER_NAME"
MYSQL_USER="root"
MYSQL_PASSWORD="$DB_ROOT_PASSWORD"
MYSQL_PORT=$DB_PORT

# Protect system DBs
PROTECTED_DBS_REGEX='^(information_schema|mysql|performance_schema|sys)$'

# ---------------------------
# Helpers
# ---------------------------
die() { echo "Error: $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

docker_mysql() {
  # Runs `mysql` inside the container.
  # We pass password only if set (so it won't prompt).
  local -a cmd=(docker exec -i "$CONTAINER_NAME" mysql
    -u "$MYSQL_USER"
    --batch --skip-column-names
    -P "$MYSQL_PORT"
  )
  if [[ -n "$MYSQL_PASSWORD" ]]; then
    cmd+=("-p$MYSQL_PASSWORD")
  fi
  "${cmd[@]}" -e "$1"
}

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N]: " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

# ---------------------------
# Preconditions
# ---------------------------
need_cmd docker

docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME" \
  || die "Container '$CONTAINER_NAME' not running (set MYSQL_CONTAINER=... to override)."

# ---------------------------
# Fetch databases
# ---------------------------
mapfile -t DBS < <(docker_mysql "SHOW DATABASES;")

SAFE_DBS=()
for db in "${DBS[@]}"; do
  [[ "$db" =~ $PROTECTED_DBS_REGEX ]] && continue
  SAFE_DBS+=("$db")
done

if (( ${#SAFE_DBS[@]} == 0 )); then
  echo "No databases found (excluding protected/system DBs)."
  exit 0
fi

echo "MySQL in Docker container: $CONTAINER_NAME"
echo

# ---------------------------
# Safety confirmations
# ---------------------------
if ! confirm "Are you sure you want to clear all databases?"; then
  echo "Cancelled."
  exit 0
fi

echo
echo "Type exactly: CLEAR to confirm irreversible deletion."
read -r -p "> " final
[[ "$final" == "CLEAR" ]] || { echo "Cancelled."; exit 0; }

# ---------------------------
# Execute
# ---------------------------
for db in "${SAFE_DBS[@]}"; do
  [[ "$db" =~ $PROTECTED_DBS_REGEX ]] && { echo "Skipping protected DB: $db"; continue; }
  echo "Dropping: $db"
  docker_mysql "DROP DATABASE \`$db\`;"
done

echo
echo "Done."