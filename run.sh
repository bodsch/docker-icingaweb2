#!/bin/bash

. config.rc

if [ $(docker ps -a | grep ${CONTAINER_NAME} | awk '{print $NF}' | wc -l) -gt 0 ]
then
  docker kill ${CONTAINER_NAME} 2> /dev/null
  docker rm   ${CONTAINER_NAME} 2> /dev/null
fi

DATABASE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${USER}-mysql)
GRAPHITE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${USER}-graphite)
ICINGA2_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${USER}-icinga2)

[ -z ${DATABASE_IP} ] && { echo "No Database Container '${USER}-mysql' running!"; exit 1; }
[ -z ${GRAPHITE_IP} ] && { echo "No Graphite Container '${USER}-graphite' running!"; exit 1; }
[ -z ${ICINGA2_IP} ] && { echo "No Icinga2 Container '${USER}-icinga2' running!"; exit 1; }

DOCKER_DBA_ROOT_PASS=${DOCKER_DBA_ROOT_PASS:-foo.bar.Z}
DOCKER_IDO_PASS=${DOCKER_IDO_PASS:-1W0svLTg7Q1rKiQrYjdV}
DOCKER_ICINGAWEB_PASS=${DOCKER_ICINGAWEB_PASS:-T7CVdvA0mqzGN6pH5Ne4}

# ---------------------------------------------------------------------------------------

docker run \
  --interactive \
  --tty \
  --detach \
  --publish=80:80 \
  --volume=${PWD}/share/icinga2:/usr/local/share/icinga2 \
  --volumes-from ${USER}-icinga2 \
  --link=${USER}-mysql:database \
  --link=${USER}-icinga2:icinga2 \
  --env MYSQL_HOST=${DATABASE_IP} \
  --env MYSQL_PORT=3306 \
  --env MYSQL_USER=root \
  --env MYSQL_PASS=${DOCKER_DBA_ROOT_PASS} \
  --env IDO_PASSWORD=${DOCKER_IDO_PASS} \
  --env ICINGAWEB2_PASSWORD=${DOCKER_ICINGAWEB_PASS} \
  --env ICINGAADMIN_USER=icinga \
  --env ICINGAADMIN_PASS=icinga \
  --env LIVESTATUS_HOST=${ICINGA2_IP} \
  --env LIVESTATUS_PORT=6666 \
  --hostname=${USER}-${TYPE} \
  --name ${CONTAINER_NAME} \
  ${TAG_NAME}

# ---------------------------------------------------------------------------------------
# EOF
