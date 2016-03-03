#!/bin/bash

initfile=/opt/run.init

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-""}
MYSQL_USER=${MYSQL_USER:-"root"}
MYSQL_PASS=${MYSQL_PASS:-""}

LIVESTATUS_HOST=${LIVESTATUS_HOST:-localhost}
LIVESTATUS_PORT=${LIVESTATUS_PORT:-6666}

if [ -z ${MYSQL_HOST} ]
then
  echo " [E] no '${MYSQL_HOST}' ..."
  exit 1
fi

mysql_opts="--host=${MYSQL_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASS} --port=${MYSQL_PORT}"

# wait for needed database
while ! nc -z ${MYSQL_HOST} ${MYSQL_PORT}
do
  sleep 3s
done

# must start initdb and do other jobs well
sleep 10s

# -------------------------------------------------------------------------------------------------

env | grep BLUEPRINT  > /etc/env.vars
env | grep HOST_     >> /etc/env.vars

chmod 1777 /tmp

chown root:icingaweb2 /etc/icingaweb2
chmod 2770 /etc/icingaweb2
chown -R www-data:icingaweb2 /etc/icingaweb2/*
find /etc/icingaweb2 -type f -name "*.ini" -exec chmod 660 {} \;
find /etc/icingaweb2 -type d -exec chmod 2770 {} \;

if [ ! -f "${initfile}" ]
then
  # Passwords...
  IDO_PASSWORD=${IDO_PASSWORD:-$(pwgen -s 15 1)}
  ICINGAWEB2_PASSWORD=${ICINGAWEB2_PASSWORD:-$(pwgen -s 15 1)}
  ICINGAADMIN_USER=${ICINGAADMIN_USER:-"icinga"}
  ICINGAADMIN_PASS=$(openssl passwd -1 "icinga")

  (
    echo "CREATE DATABASE IF NOT EXISTS icingaweb2;"
    echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON icingaweb2.* TO 'icingaweb2'@'%' IDENTIFIED BY '${ICINGAWEB2_PASSWORD}';"
  ) | mysql ${mysql_opts}

  mysql ${mysql_opts} --force  icingaweb2      < /usr/share/icingaweb2/etc/schema/mysql.schema.sql               >> /opt/icingaweb2-schema.log 2>&1

  (
    echo "USE icingaweb2;"
    echo "INSERT IGNORE INTO icingaweb_user (name, active, password_hash) VALUES ('${ICINGAADMIN_USER}', 1, '${ICINGAADMIN_PASS}');"
    echo "quit"
  ) | mysql ${mysql_opts}

  mkdir -vp /etc/icingaweb2/enabledModules

  ln -s /usr/share/icingaweb2/modules/* /etc/icingaweb2/enabledModules/

  for m in monitoring setup
  do
    /usr/bin/icingacli enable ${m}
  done

  chown -R www-data:icingaweb2 /etc/icingaweb2/*

  sed -i 's,icingaweb2_changeme,'${ICINGAWEB2_PASSWORD}',g' /etc/icingaweb2/resources.ini
  sed -i 's,icinga2-ido-mysq_changeme,'${IDO_PASSWORD}',g'  /etc/icingaweb2/resources.ini
  sed -i 's,dba-host_changeme,'${MYSQL_HOST}',g'            /etc/icingaweb2/resources.ini

  sed -i 's,%LIVESTATUS_HOST%,'${LIVESTATUS_HOST}',g'       /etc/icingaweb2/resources.ini
  sed -i 's,%LIVESTATUS_PORT%,'${LIVESTATUS_PORT}',g'       /etc/icingaweb2/resources.ini

  sed -i 's,icingaadmin_changeme,'${ICINGAADMIN_USER}',g'   /etc/icingaweb2/roles.ini

  mkdir -p /var/log/icingaweb2
  chown www-data:adm /var/log/icingaweb2

  touch ${initfile}

  echo -e "\n"
  echo " ==================================================================="
  echo " MySQL user 'icingaweb2' password set to ${ICINGAWEB2_PASSWORD}"
  echo " IcingaWeb2 Adminuser '${ICINGAADMIN_USER}' password set to ${ICINGAADMIN_PASS}"
  echo " ==================================================================="
  echo ""

fi

echo -e "\n Starting Supervisor.\n  You can safely CTRL-C and the container will continue to run with or without the -d (daemon) option\n\n"

if [ -f /etc/supervisor/conf.d/icingaweb2.conf ]
then
  /usr/bin/supervisord -c /etc/supervisor/conf.d/icingaweb2.conf >> /dev/null
else
  exec /bin/bash
fi

# EOF
