#!/usr/bin/env bash

BASEDIR=$(dirname "$0")
ENV_FILE="$BASEDIR"/../.env

if ! test -f "$ENV_FILE"; then
    echo "❌ .env file not found at $ENV_FILE. Please create it first using ./scripts/create_environment.sh"
    exit 1
fi

source $ENV_FILE

env_variable_keys=("WEB_CONTAINER_NAME" "DB_CONTAINER_NAME" "DB_ROOT_PASSWORD" "DB_PORT")
for key in "${env_variable_keys[@]}"; do
    if [ -z "${!key}" ]; then
        echo "❌ Environment variable $key is missing from the .env file"
        exit 1
    fi
done

re='^[0-9]+$'
if ! [[ "$DB_PORT" =~ $re ]] ; then
   echo "❌ DB_PORT must be a number!" >&2
   exit 1
fi