#!/bin/bash
#
#

MYSQL_HOST=${MYSQL_HOST:-"database"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=

ICINGA2_API_PORT=${ICINGA2_API_PORT:-5665}
ICINGA2_UPTIME=${ICINGA2_UPTIME:-125}

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

export ICINGAWEB_DIRECTOR=${ICINGAWEB_DIRECTOR:-"true"}

. /init/output.sh

# -------------------------------------------------------------------------------------------------

if [[ -z ${MYSQL_HOST} ]]
then
  log_error "no MYSQL_HOST set ..."
  exit 1
else
  MYSQL_OPTS=
  MYSQL_OPTS="${MYSQL_OPTS} --host=${MYSQL_HOST}"
  MYSQL_OPTS="${MYSQL_OPTS} --port=${MYSQL_PORT}"
  MYSQL_OPTS="${MYSQL_OPTS} --user=${MYSQL_ROOT_USER}"
  MYSQL_OPTS="${MYSQL_OPTS} --password=${MYSQL_ROOT_PASS}"
  export MYSQL_OPTS
fi

# -------------------------------------------------------------------------------------------------

prepare() {

  MYSQL_ICINGAWEB2_PASSWORD=icingaweb2

  touch /etc/icingaweb2/resources.ini
  touch /etc/icingaweb2/roles.ini

  [[ -e /etc/php/php.ini ]] || cp /etc/php7/php.ini /etc/php/php.ini
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


configure_modules() {

  log_info "configure modules"

  if [[ -d /init/modules.d ]]
  then
    for f in /init/modules.d/*
    do
      case "$f" in
        *.sh)
          if [[ -x ${f} ]]
          then
            # log_debug "execute file: $(basename ${f})"
            ${f}  # > /proc/self/fd/2 2>&1
          else
            log_warn "file '${f}' is not executable"
          fi
          ;;
        *)
          # log_warn "ignoring file ${f}"
          ;;
      esac
    done
  fi
}

run() {

  prepare

  . /init/database/mysql.sh

  . /init/wait_for/icinga_master.sh
  . /init/create_login_users.sh

  configure_modules

#  . /init/configure_modules/commandtransport.sh
#  . /init/configure_modules/graphite.sh
#  . /init/configure_modules/director.sh
#
#  . /init/configure_modules/authentication.sh
#  # . /init/database/fix_latin1_db_statements.sh

  correctRights

  nohup /usr/bin/php-fpm \
    --fpm-config /etc/php/php-fpm.conf \
    --pid /run/php-fpm.pid \
    --allow-to-run-as-root \
    --nodaemonize > /proc/self/fd/2 2>&1 &
  /usr/sbin/nginx > /proc/self/fd/2 2>&1
}


run

# EOF
