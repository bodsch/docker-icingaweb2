#!/bin/bash
#
#

if [ ${DEBUG} ]
then
  set -x
fi

WORK_DIR="/srv/icingaweb2"

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

# -------------------------------------------------------------------------------------------------

if [ -z ${MYSQL_HOST} ]
then
  echo " [i] no MYSQL_HOST set ..."
else
  export MYSQL_OPTS="--host=${MYSQL_HOST} --user=${MYSQL_ROOT_USER} --password=${MYSQL_ROOT_PASS} --port=${MYSQL_PORT}"
fi

# -------------------------------------------------------------------------------------------------

prepare() {

  [ -d ${WORK_DIR} ] || mkdir -p ${WORK_DIR}

  MYSQL_ICINGAWEB2_PASSWORD=icingaweb2 # $(pwgen -s 15 1)
#   ICINGAWEB_ADMIN_PASSWORD=$(openssl passwd -1 ${ICINGAWEB_ADMIN_PASS})

#  [ -f /etc/icingaweb2/resources.ini ] && rm -f /etc/icingaweb2/resources.ini
  touch /etc/icingaweb2/resources.ini
  touch /etc/icingaweb2/roles.ini
}


correctRights() {

  chmod 1777 /tmp
  chmod 2770 /etc/icingaweb2

  chown root:nginx     /etc/icingaweb2
  chown -R nginx:nginx /etc/icingaweb2/*

  find /etc/icingaweb2 -type f -name "*.ini" -exec chmod 0660 {} \;
  find /etc/icingaweb2 -type d -exec chmod 2770 {} \;

  chown nginx:nginx /var/log/icingaweb2

}


startSupervisor() {

  echo -e "\n Starting Supervisor.\n\n"

  if [ -f /etc/supervisord.conf ]
  then
    /usr/bin/supervisord -c /etc/supervisord.conf >> /dev/null
  else
    exec /bin/sh
  fi
}


run() {

  prepare

  . /init/database/mysql.sh
  . /init/configure_director.sh
  . /init/configure_commandtransport.sh
#  . /init/configure_livestatus.sh
  . /init/configure_graphite.sh
  . /init/users.sh

  correctRights

  startSupervisor
}


run

# EOF
