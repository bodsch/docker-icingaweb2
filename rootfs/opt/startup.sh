#!/bin/bash
#
#

if [ ${DEBUG} ]
then
  set -x
fi

WORK_DIR=${WORK_DIR:-/srv}
WORK_DIR=${WORK_DIR}/icingaweb2

initfile=${WORK_DIR}/run.init

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

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

  [ -d ${WORK_DIR} ] || mkdir -p ${WORK_DIR}

  MYSQL_ICINGAWEB2_PASSWORD=$(pwgen -s 15 1)
  ICINGAWEB_ADMIN_PASSWORD=$(openssl passwd -1 ${ICINGAWEB_ADMIN_PASS})

  [ -f /etc/icingaweb2/resources.ini ] && rm -f /etc/icingaweb2/resources.ini

  touch /etc/icingaweb2/resources.ini
}

configureIcingaWeb() {

  local status="${WORK_DIR}/mysql-schema.import"

  if [ ! -f "${status}" ]
  then

    (
      echo "CREATE DATABASE IF NOT EXISTS icingaweb2 DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON icingaweb2.* TO 'icingaweb2'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
    ) | mysql ${mysql_opts}

    if [ $? -eq 0 ]
    then
      touch ${status}
    else
      echo " [E] can't create the icingaweb2 Database"
      exit 1
    fi

    SCHEMA_FILE="/usr/share/webapps/icingaweb2/etc/schema/mysql.schema.sql"

    if [ -f ${SCHEMA_FILE} ]
    then

      mysql ${mysql_opts} --force  icingaweb2 < ${SCHEMA_FILE} >> ${WORK_DIR}/icingaweb2-schema.log 2>&1

      if [ $? -eq 0 ]
      then
        touch ${status}
      else
        echo " [E] can't insert the icingaweb2 Database Schema"
        exit 1
      fi

      (
        echo "USE icingaweb2;"
        echo "INSERT IGNORE INTO icingaweb_user (name, active, password_hash) VALUES ('${ICINGAWEB_ADMIN_USER}', 1, '${ICINGAWEB_ADMIN_PASSWORD}');"
        echo "quit"
      ) | mysql ${mysql_opts}

      if [ $? -eq 0 ]
      then
        touch ${status}
      else
        echo " [E] can't create the icingaweb User"
        exit 1
      fi
    fi

    cat << EOF >> /etc/icingaweb2/resources.ini

[icingaweb_db]
type                = "db"
db                  = "mysql"
host                = "${MYSQL_HOST}"
port                = "3306"
dbname              = "icingaweb2"
username            = "icingaweb2"
password            = "${MYSQL_ICINGAWEB2_PASSWORD}"
prefix              = "icingaweb_"

EOF

    if [ ! -z ${IDO_PASSWORD} ]
    then

      cat << EOF >> /etc/icingaweb2/resources.ini

[icinga_ido]
type                = "db"
db                  = "mysql"
host                = "${MYSQL_HOST}"
port                = "3306"
dbname              = "icinga2"
username            = "icinga2"
password            = "${IDO_PASSWORD}"

EOF
    else
      echo " [i] IDO_PASSWORD isn't set."
      echo " [i] disable IDO Access for Icingaweb"

    fi


    sed -i \
      's,%ICINGAWEB_ADMIN_USER%,'${ICINGAWEB_ADMIN_USER}',g' \
      /etc/icingaweb2/roles.ini
  fi

}

configureIcingaDirector() {

  # icingaweb director
  if [ -d /usr/share/webapps/icingaweb2/modules/director ]
  then
    (
      echo "CREATE DATABASE IF NOT EXISTS director DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
      echo "GRANT ALL ON director.* TO 'director'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
      echo "quit"
    ) | mysql ${mysql_opts}

    SCHEMA_FILE="/usr/share/webapps/icingaweb2/modules/director/schema/mysql.sql"

    if [ -f ${SCHEMA_FILE} ]
    then
      mysql ${mysql_opts} --force  director < ${SCHEMA_FILE} >> ${WORK_DIR}/icingaweb2-director.log 2>&1

      cat << EOF >> /etc/icingaweb2/resources.ini

[director]
type                = "db"
db                  = "mysql"
host                = "${MYSQL_HOST}"
port                = "3306"
dbname              = "director"
username            = "director"
password            = "${MYSQL_ICINGAWEB2_PASSWORD}"

EOF
    fi
  fi
}

configureIcingaLivestatus() {

  if ( [ ! -z ${LIVESTATUS_HOST} ] && [ ! -z ${LIVESTATUS_PORT} ] )
  then
    echo " [i] enable Live status for Host '${LIVESTATUS_HOST}'"

    cat << EOF >> /etc/icingaweb2/resources.ini

[livestatus-tcp]
type                = "livestatus"
socket              = "tcp://${LIVESTATUS_HOST}:${LIVESTATUS_PORT}"

EOF

  fi

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

  if [ ! -f "${initfile}" ]
  then
    waitForDatabase
    prepare
    configureIcingaWeb
    configureIcingaDirector
    configureIcingaLivestatus

    correctRights

    echo -e "\n"
    echo " ==================================================================="
    echo " MySQL user 'icingaweb2' password set to '${MYSQL_ICINGAWEB2_PASSWORD}'"
    echo " IcingaWeb2 Adminuser '${ICINGAWEB_ADMIN_USER}' password set to '${ICINGAWEB_ADMIN_PASS}'"
    echo " ==================================================================="
    echo ""
  fi

  startSupervisor
}


run

# EOF
