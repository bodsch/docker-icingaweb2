#!/bin/bash
#
#

[[ ${DEBUG} ]] && set -x

WORK_DIR="/srv/icingaweb2"

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=

ICINGA2_API_PORT=${ICINGA2_API_PORT:-5665}

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

GRAPHITE_HOST=${GRAPHITE_HOST:-""}
GRAPHITE_HTTP_PORT=${GRAPHITE_HTTP_PORT:-8080}

. /init/output.sh

# -------------------------------------------------------------------------------------------------

if [[ -z ${MYSQL_HOST} ]]
then
  log_info "no MYSQL_HOST set ..."
else
  export MYSQL_OPTS="--host=${MYSQL_HOST} --user=${MYSQL_ROOT_USER} --password=${MYSQL_ROOT_PASS} --port=${MYSQL_PORT}"
fi

# -------------------------------------------------------------------------------------------------

prepare() {

  [[ -d ${WORK_DIR} ]] || mkdir -p ${WORK_DIR}

  MYSQL_ICINGAWEB2_PASSWORD=icingaweb2

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

# side channel to inject some wild-style customized scripts
#
custom_scripts() {

  if [[ -d /init/custom.d ]]
  then
    for f in /init/custom.d/*
    do
      case "$f" in
        *.sh)
          log_WARN "------------------------------------------------------"
          log_WARN "RUN SCRIPT: ${f}"
          log_WARN "YOU SHOULD KNOW WHAT YOU'RE DOING."
          log_WARN "THIS CAN BREAK THE COMPLETE ICINGA2 CONFIGURATION!"
          nohup "${f}" > /dev/stdout 2>&1 &
          log_WARN "------------------------------------------------------"
          ;;
        *)
          log_warn "ignoring file ${f}"
          ;;
      esac
      echo
    done
  fi
}



run() {

  prepare

  . /init/database/mysql.sh

  . /init/wait_for/icinga_master.sh

  . /init/configure_commandtransport.sh
  . /init/configure_graphite.sh
  . /init/configure_director.sh

  . /init/users.sh
  . /init/configure_authentication.sh
  . /init/fix_latin1_db_statements.sh

  correctRights

  nohup /usr/bin/php-fpm --fpm-config /etc/php/php-fpm.conf --pid /run/php-fpm.pid --allow-to-run-as-root --nodaemonize > /dev/stdout 2>&1 &
  /usr/sbin/nginx > /dev/stdout 2>&1
}


run

# EOF
