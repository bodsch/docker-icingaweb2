#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  reporting"

REPORTING_DATABASE_USER=${REPORTING_DATABASE_USER:-"reporting"}
REPORTING_DATABASE_PASS=${REPORTING_DATABASE_PASS:-"reporting"}
REPORTING_DATABASE_NAME=${REPORTING_DATABASE_NAME:-"reporting"}
MYSQL_UOPTS="--host=${MYSQL_HOST} --user=${REPORTING_DATABASE_USER} --password=${REPORTING_DATABASE_PASS} --port=${MYSQL_PORT}"


check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/reporting"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then
    create_user

    create_database

    create_schema

    [[ -d /etc/icingaweb2/modules/reporting ]] || mkdir -p /etc/icingaweb2/modules/reporting

    log_info "    create config files for icingaweb"

    if [[ $(grep -c "reporting" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[reporting]
type       = "db"
db         = "mysql"
host       = "${MYSQL_HOST}"
port       = "${MYSQL_PORT}"
dbname     = "${REPORTING_DATABASE_USER}"
username   = "${REPORTING_DATABASE_NAME}"
password   = "${REPORTING_DATABASE_PASS}"
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

# create database user
#
create_user() {

  # check if user is already created ...
  #
  query="SHOW DATABASES;"

  status=$(mysql ${MYSQL_UOPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # user isn't created
    # well, i do my job ...
    #

    log_info "      - initializing reporting db user"
    (
      echo "CREATE USER '${REPORTING_DATABASE_USER}'@'%' IDENTIFIED BY '${REPORTING_DATABASE_PASS}';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "failed to create user: '${REPORTING_DATABASE_USER}'"
      exit 1
    fi
  fi
}

# create database
#
create_database() {

  # check if database already created ...
  #
  query="SHOW DATABASES LIKE '${REPORTING_DATABASE_NAME}'"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #

    log_info "      - initializing reporting databases"
    (
      echo "CREATE DATABASE IF NOT EXISTS ${REPORTING_DATABASE_NAME} DEFAULT CHARACTER SET 'utf8mb4' COLLATE utf8mb4_bin;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${REPORTING_DATABASE_NAME}.* TO '${REPORTING_DATABASE_USER}'@'%' IDENTIFIED BY '${REPORTING_DATABASE_PASS}';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "can't create database '${REPORTING_DATABASE_NAME}'"
      exit 1
    fi
  fi
}

# create web database schema
#
create_schema() {

  # check if database scheme is already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = \"${REPORTING_DATABASE_NAME}\" limit 1;"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  local database_name="${REPORTING_DATABASE_NAME}"
  local modules_directory="${ICINGAWEB_MODULES_DIRECTORY}/reporting"

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then

    SCHEMA_FILE="${modules_directory}/schema/mysql.sql"

    if [[ -f ${SCHEMA_FILE} ]]
    then
      log_info "      import database schema"

      mysql ${MYSQL_OPTS} --force ${database_name} < ${SCHEMA_FILE}

      if [[ $? -gt 0 ]]
      then
        log_error "can't insert the director Database Schema"
        exit 1
      fi
    else
      log_warn "missing schema file"
    fi
  fi
}


check
configure
