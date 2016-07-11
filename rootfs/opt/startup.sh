#!/bin/bash
#
#

# set -x


WORK_DIR=${WORK_DIR:-/srv}
WORK_DIR=${WORK_DIR}/icingaweb2

initfile=${WORK_DIR}/run.init

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

LIVESTATUS_HOST=${LIVESTATUS_HOST:-localhost}
LIVESTATUS_PORT=${LIVESTATUS_PORT:-6666}

if [ -z ${MYSQL_HOST} ]
then
  echo " [E] no MYSQL_HOST var set ..."
  exit 1
fi

mysql_opts="--host=${MYSQL_HOST} --user=${MYSQL_ROOT_USER} --password=${MYSQL_ROOT_PASS} --port=${MYSQL_PORT}"

# -------------------------------------------------------------------------------------------------

waitForDatabase() {

  # wait for needed database
  while ! nc -z ${MYSQL_HOST} ${MYSQL_PORT}
  do
    sleep 3s
  done

  # must start initdb and do other jobs well
  echo " [i] wait for database for there initdb and do other jobs well"
  sleep 10s
}

prepare() {

  chmod 1777 /tmp

  chown root:nginx   /etc/icingaweb2
  chown -R nginx:nginx /etc/icingaweb2/*

  chmod 2770 /etc/icingaweb2

  find /etc/icingaweb2 -type f -name "*.ini" -exec chmod 660 {} \;
  find /etc/icingaweb2 -type d -exec chmod 2770 {} \;
}

configureIcingaWeb() {

  if [ ! -f "${initfile}" ]
  then
    # Passwords...

    MYSQL_ICINGAWEB2_PASSWORD=$(pwgen -s 15 1)

#     IDO_PASSWORD=${IDO_PASSWORD:-$(pwgen -s 15 1)}
#     ICINGAWEB2_PASSWORD=${ICINGAWEB2_PASSWORD:-$(pwgen -s 15 1)}
#     ICINGAADMIN_USER=${ICINGAADMIN_USER:-"icinga"}
    ICINGAWEB_ADMIN_PASSWORD=$(openssl passwd -1 '${ICINGAWEB_ADMIN_PASS}')

    (
      echo "CREATE DATABASE IF NOT EXISTS icingaweb2 DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON icingaweb2.* TO 'icingaweb2'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
    ) | mysql ${mysql_opts}

    SCHEMA_FILE="/usr/share/webapps/icingaweb2/etc/schema/mysql.schema.sql"

    mysql ${mysql_opts} --force  icingaweb2      < ${SCHEMA_FILE}               >> ${WORK_DIR}/icingaweb2-schema.log 2>&1

    (
      echo "USE icingaweb2;"
      echo "INSERT IGNORE INTO icingaweb_user (name, active, password_hash) VALUES ('${ICINGAWEB_ADMIN_USER}', 1, '${ICINGAWEB_ADMIN_PASSWORD}');"
      echo "quit"
    ) | mysql ${mysql_opts}

    # icingaweb director
    if [ -d /usr/share/webapps/icingaweb2/modules/director ]
    then
      (
        echo "CREATE DATABASE IF NOT EXISTS director DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
        echo "GRANT ALL ON director.* TO 'director'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
        echo "quit"
      ) | mysql ${mysql_opts}

      SCHEMA_FILE="/usr/share/webapps/icingaweb2/modules/director/schema/mysql.sql"

      mysql ${mysql_opts} --force  director < ${SCHEMA_FILE}               >> ${WORK_DIR}/icingaweb2-director.log 2>&1
    fi

    chown -R nginx:nginx /etc/icingaweb2/*

    sed -i \
      -e 's,%MYSQL_ICINGAWEB2_PASSWORD%,'${MYSQL_ICINGAWEB2_PASSWORD}',g' \
      -e 's,%MYSQL_IDO_PASSWORD%,'${IDO_PASSWORD}',g' \
      -e 's,%MYSQL_HOST%,'${MYSQL_HOST}',g' \
      -e 's,%LIVESTATUS_HOST%,'${LIVESTATUS_HOST}',g' \
      -e 's,%LIVESTATUS_PORT%,'${LIVESTATUS_PORT}',g' \
      /etc/icingaweb2/resources.ini

    sed -i 's,%ICINGAWEB_ADMIN_USER%,'${ICINGAWEB_ADMIN_USER}',g'   /etc/icingaweb2/roles.ini

    chown nginx:nginx /var/log/icingaweb2

    touch ${initfile}
  fi

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

  if [ ! -f "${initfile}" ]
  then
    waitForDatabase
    prepare
    configureIcingaWeb

    echo -e "\n"
    echo " ==================================================================="
    echo " MySQL user 'icingaweb2' password set to ${MYSQL_ICINGAWEB2_PASSWORD}"
    echo " IcingaWeb2 Adminuser '${ICINGAWEB_ADMIN_USER}' password set to '${ICINGAWEB_ADMIN_PASS}'"
    echo " ==================================================================="
    echo ""
  fi

  startSupervisor
}


run

# EOF
