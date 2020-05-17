#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  idoreports"

IDO_USER=${IDO_USER:-"icinga2"}
ICINGAWEB_IDOREPORTS=${ICINGAWEB_IDOREPORTS:-"true"}


check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1

  if [[ "${ICINGAWEB_IDOREPORTS}" = "false" ]]
  then
    log_info "    idoreports support is disabled"

    disable_module idoreports
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/idoreports"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then
    create_database

    [[ -d /etc/icingaweb2/modules/idoreports ]] || mkdir -p /etc/icingaweb2/modules/idoreports

    log_info "    enabling ido reports"

    enable_module idoreports
  fi
}

create_database() {

  local database_name="${IDO_DATABASE_NAME}"
  local modules_directory="${ICINGAWEB_MODULES_DIRECTORY}/idoreports"

  # check if table is already created ...
  #
  query="SELECT * FROM information_schema.tables WHERE table_schema = '${database_name}' AND table_name = 'icinga_sla_periods' limit 1;"

  database_status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w )

  if [[ ${database_status} -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #
    log_info "      - fixing grants for idoreports module"
    (
      echo "GRANT CREATE, CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON ${database_name}.* TO '${IDO_USER}'@'%';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    SCHEMA_FILE_PERIODS="${modules_directory}/schema/slaperiods.sql"
    SCHEMA_FILE_PERCENT="${modules_directory}/schema/get_sla_ok_percent.sql"

    if [[ -f ${SCHEMA_FILE_PERIODS} ]]
    then
      log_info "      - import database schema periods"

      mysql ${MYSQL_OPTS} --force ${database_name} < ${SCHEMA_FILE_PERIODS}

      if [[ $? -gt 0 ]]
      then
        log_error "can't insert the Database Schema"
        exit 1
      fi
    else
      log_warn "missing schema file"
    fi

    if [[ -f ${SCHEMA_FILE_PERCENT} ]]
    then
      log_info "      - import database schema percent"

      mysql ${MYSQL_OPTS} --force ${database_name} < ${SCHEMA_FILE_PERCENT}

      if [[ $? -gt 0 ]]
      then
        log_error "can't insert the Database Schema"
        exit 1
      fi
    else
      log_warn "missing schema file"
    fi

  fi
}

check
configure
