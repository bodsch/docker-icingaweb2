#!/bin/bash
#
#

MYSQL_HOST=${MYSQL_HOST:-"database"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=

XDEBUG_ENABLED=${XDEBUG_ENABLED:-""}

ICINGA2_API_PORT=${ICINGA2_API_PORT:-5665}
ICINGA2_UPTIME=${ICINGA2_UPTIME:-125}

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

export ICINGAWEB_DIRECTOR=${ICINGAWEB_DIRECTOR:-"true"}
export ICINGAWEB_MODULES_DIRECTORY=/usr/share/icingaweb2/modules

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

  for p in HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
  do
    unset "${p}"
  done

  MYSQL_ICINGAWEB2_PASSWORD=icingaweb2

  touch /etc/icingaweb2/resources.ini
  touch /etc/icingaweb2/roles.ini

  if [[ -n "$XDEBUG_ENABLED" ]] && [[ -f /usr/lib/php7/modules/xdebug.so ]]
  then
    log_info "Enabling xdebug"
    cp /etc/php7/conf.d/ext-xdebug.ini.disabled /etc/php7/conf.d/xdebug.ini

    cat << EOF >> /etc/php7/conf.d/xdebug.ini

[Xdebug]
xdebug.remote_enable=true
xdebug.remote_connect_back=true
xdebug.profiler_enable=0
xdebug.profiler_output_dir=/tmp/profile
xdebug.profiler_enable_trigger=1
EOF
  fi
}


correct_rights() {

  chmod 1777 /tmp
  chmod 2770 /etc/icingaweb2

  chown root:www-data     /etc/icingaweb2
  chown -R www-data:www-data /etc/icingaweb2/*
  # chown -R www-data:www-data /run/php/*

  find /etc/icingaweb2 -type f -name "*.ini" -exec chmod 0660 {} \;
  find /etc/icingaweb2 -type d -exec chmod 2770 {} \;

  chown www-data:www-data /var/log/icingaweb2
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
          nohup "${f}" > /proc/self/fd/2 2>&1 &
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

  [[ -e /etc/icingaweb2/enabledModules/reactbundle ]] || ln -s /usr/share/icingaweb2/modules/reactbundle /etc/icingaweb2/enabledModules/
  [[ -e /etc/icingaweb2/enabledModules/incubator ]]   || ln -s /usr/share/icingaweb2/modules/incubator /etc/icingaweb2/enabledModules/
  [[ -e /etc/icingaweb2/enabledModules/ipl ]]         || ln -s /usr/share/icingaweb2/modules/ipl /etc/icingaweb2/enabledModules/

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
            sleep 1s
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
  correct_rights
}

run

# EOF
