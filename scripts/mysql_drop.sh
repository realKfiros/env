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
MYSQL_EXTRA_ARGS="${MYSQL_EXTRA_ARGS:-}" # e.g. "--protocol=tcp"

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
    $MYSQL_EXTRA_ARGS
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
# Selection UI
# ---------------------------
SELECTED=()

if command -v fzf >/dev/null 2>&1; then
  echo "Select DB(s) to DROP (TAB to multi-select), then Enter:"
  mapfile -t SELECTED < <(printf '%s\n' "${SAFE_DBS[@]}" | fzf --multi --prompt="DROP> ")
else
  echo "fzf not found, using numbered menu."
  echo "Enter numbers separated by spaces (e.g. 1 3 5)."
  echo

  i=1
  for db in "${SAFE_DBS[@]}"; do
    printf "%3d) %s\n" "$i" "$db"
    ((i++))
  done

  echo
  read -r -p "Numbers to drop: " nums

  for n in $nums; do
    if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#SAFE_DBS[@]} )); then
      SELECTED+=("${SAFE_DBS[$((n-1))]}")
    fi
  done
fi

if (( ${#SELECTED[@]} == 0 )); then
  echo "Nothing selected. Exiting."
  exit 0
fi

# Deduplicate
mapfile -t SELECTED < <(printf "%s\n" "${SELECTED[@]}" | awk '!seen[$0]++')

echo
echo "You selected to DROP these databases:"
printf " - %s\n" "${SELECTED[@]}"
echo

# ---------------------------
# Safety confirmations
# ---------------------------
if ! confirm "Are you sure you want to DROP these databases?"; then
  echo "Cancelled."
  exit 0
fi

echo
echo "Type exactly: DROP to confirm irreversible deletion."
read -r -p "> " final
[[ "$final" == "DROP" ]] || { echo "Cancelled."; exit 0; }

# ---------------------------
# Execute
# ---------------------------
for db in "${SELECTED[@]}"; do
  [[ "$db" =~ $PROTECTED_DBS_REGEX ]] && { echo "Skipping protected DB: $db"; continue; }
  echo "Dropping: $db"
  docker_mysql "DROP DATABASE \`$db\`;"
done

echo
echo "Done."