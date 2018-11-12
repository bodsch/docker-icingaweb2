#!/bin/bash

set -e

WORK_DIR=$(dirname $(readlink --canonicalize "${0}"))
PARENT_DIR=$(dirname $(readlink --canonicalize "${0%/*}"))

DOCKER_COMPOSE=(docker-compose --file "${PARENT_DIR}/docker-compose.yml")

[[ -f "${PARENT_DIR}/docker-compose.yml" ]] || make compose-file

# Check docker-compose configuration and start services
${DOCKER_COMPOSE[@]} config --quiet
${DOCKER_COMPOSE[@]} up -d

sleep 10s

echo 'Waiting until Icingaweb2 has been started'

max_retry=30
retry=0

until [[ ${max_retry} -lt ${retry} ]]
do
  # -v              Verbose
  # -w secs         Timeout for connects and final net reads
  # -X proto        Proxy protocol: "4", "5" (SOCKS) or "connect"
  #
  status=$(nc -v -w1 -X connect localhost 80 2>&1 > /dev/null)

  if [[ $(echo "${status}" | grep -c succeeded) -eq 1 ]]
  then
    break
  else
    retry=$(expr ${retry} + 1)
    echo "  wait for an open port (${retry}/${max_retry})"
    sleep 5s
  fi
done

if [[ ${retry} -eq ${max_retry} ]] || [[ ${retry} -gt ${max_retry} ]]
then
  echo "ERROR: Couldn't reach Icingaweb2 via network"
  exit 1
fi

# Shutdown
${DOCKER_COMPOSE[@]} down
