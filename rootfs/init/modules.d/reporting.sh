#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  reporting"

DATABASE_REPORTING_PASSWORD="reporting"

check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/reporting"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then
    create_database

    [[ -d /etc/icingaweb2/modules/reporting ]] || mkdir -p /etc/icingaweb2/modules/reporting

    log_info "    create config files for icingaweb"

    if [[ $(grep -c "reporting" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[reporting]
type       = "db"
db         = "mysql"
host       = "${MYSQL_HOST}"
port       = 3306
dbname     = "reporting"
username   = "reporting"
password   = "${DATABASE_REPORTING_PASSWORD}"
charset    = "utf8mb4"

EOF
    fi

    if [[ ! -f /etc/icingaweb2/modules/reporting/config.ini ]]
    then
      cat << EOF > /etc/icingaweb2/modules/reporting/config.ini

[backend]
resource = "reporting"
EOF
    fi

    enable_module reporting

    log_info "    run background deamon"
    /usr/bin/icingacli \
      reporting \
      schedule \
      run &

  fi
}

create_database() {

  local database_name='reporting'
  local modules_directory="${ICINGAWEB_MODULES_DIRECTORY}/reporting"

  # check if database already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = '${database_name}' limit 1;"

  database_status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w )

  if [[ ${database_status} -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #
    log_info "      - initializing databases"
    (
      echo "--- create user 'reporting'@'%' IDENTIFIED BY '${DATABASE_REPORTING_PASSWORD}';"
      echo "CREATE DATABASE IF NOT EXISTS ${database_name} DEFAULT CHARACTER SET 'utf8mb4' COLLATE utf8mb4_bin;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'reporting'@'%' IDENTIFIED BY '${DATABASE_REPORTING_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'reporting'@'$(hostname -i)' IDENTIFIED BY '${DATABASE_REPORTING_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'reporting'@'$(hostname -s)' IDENTIFIED BY '${DATABASE_REPORTING_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'reporting'@'$(hostname -f)' IDENTIFIED BY '${DATABASE_REPORTING_PASSWORD}';"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    SCHEMA_FILE="${modules_directory}/schema/mysql.sql"

    if [[ -f ${SCHEMA_FILE} ]]
    then
      log_info "      - import database schema"

      mysql ${MYSQL_OPTS} --force ${database_name} < ${SCHEMA_FILE}

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
