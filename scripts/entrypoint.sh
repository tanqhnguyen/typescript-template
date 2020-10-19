#!/bin/sh
set -e
cmd="$@"

basedir=$(dirname "$0")

# credit: https://stackoverflow.com/a/28938235/386378
color_off='\033[0m'
green='\033[0;32m'

green() {
  text="$1"

  printf "${green}${text}${color_off}"
}

: ${ENV_SECRETS_DIR:=/run/secrets}

env_secret_debug()
{
  if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
    echo -e "\033[1m$@\033[0m"
  fi
}

# usage: env_secret_expand VAR
#  ie: env_secret_expand 'XYZ_DB_PASSWORD'
# (will check for "$XYZ_DB_PASSWORD" variable value for a placeholder that defines the
#  name of the docker secret to use instead of the original value. For example:
# XYZ_DB_PASSWORD={{DOCKER-SECRET:my-db.secret}}
env_secret_expand() {
  var="$1"
  eval val=\$$var
  if secret_name=$(expr match "$val" "DOCKER-SECRET->\([^}]\+\)$"); then
    printf "Expanding docker secret for ${var} ... "
    secret="${ENV_SECRETS_DIR}/${secret_name}"
    env_secret_debug "Secret file for $var: $secret"
    if [ -f "$secret" ]; then
      val=$(cat "${secret}")
      export "$var"="$val"
      env_secret_debug "Expanded variable: $var=$val"
    else
      env_secret_debug "Secret file does not exist! $secret"
    fi
    green "done\n"
  fi
}

env_secrets_expand() {
  for env_var in $(printenv | cut -f1 -d"=")
  do
    env_secret_expand $env_var
  done

  if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
    echo -e "\n\033[1mExpanded environment variables\033[0m"
    printenv
  fi
}

wait_for_service() {
  host="$1"
  port="$2"

  printf "Waiting for ${host}:${port} ... "
  while ! nc -z $host $port; do
    sleep 0.5
  done
  green "done\n"
}

# wait for some specific services
# if [ ! -z "$REDIS_HOST" ] && [ ! -z "$REDIS_PORT" ]; then
#   wait_for_service $REDIS_HOST $REDIS_PORT
# fi

exec $cmd
