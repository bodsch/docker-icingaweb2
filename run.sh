#!/bin/bash

. config.rc

if [ $(docker ps -a | grep ${CONTAINER_NAME} | awk '{print $NF}' | wc -l) -gt 0 ]
then
  docker kill ${CONTAINER_NAME} 2> /dev/null
  docker rm   ${CONTAINER_NAME} 2> /dev/null
fi

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
  --env MYSQL_HOST=database \
  --env MYSQL_PORT=3306 \
  --env MYSQL_USER=root \
  --env MYSQL_PASS=foo.bar.Z \
  --env IDO_PASSWORD=xxxxxxxxx \
  --env ICINGAWEB2_PASSWORD=xxxxxxxxx \
  --env ICINGAADMIN_USER=icinga \
  --env ICINGAADMIN_PASS=icinga \
  --env LIVESTATUS_HOST=icinga2 \
  --env LIVESTATUS_PORT=6666 \
  --dns=${DOCKER_DNS} \
  --hostname=${USER}-${TYPE} \
  --name ${CONTAINER_NAME} \
  ${TAG_NAME}

# ---------------------------------------------------------------------------------------
# EOF
