#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  vspheredb"

ICINGAWEB_VSPHEREDB=${ICINGAWEB_VSPHEREDB:-"true"}
VSPHEREDB_DATABASE_USER=${VSPHEREDB_DATABASE_USER:-"vspheredb"}
VSPHEREDB_DATABASE_PASS=${VSPHEREDB_DATABASE_PASS:-"vspheredb"}
VSPHEREDB_DATABASE_NAME=${VSPHEREDB_DATABASE_NAME:-"vspheredb"}
MYSQL_UOPTS="--host=${MYSQL_HOST} --user=${VSPHEREDB_DATABASE_USER} --password=${VSPHEREDB_DATABASE_PASS} --port=${MYSQL_PORT}"

check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1

  if [[ "${ICINGAWEB_VSPHEREDB}" = "false" ]]
  then
    log_info "    vspheredb support is disabled"

    disable_module vspheredb
    exit 0
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

    log_info "      initializing vspheredb user"
    (
      echo "create user '${VSPHEREDB_DATABASE_USER}'@'%' IDENTIFIED BY '${VSPHEREDB_DATABASE_PASS}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "failed to create user: '${VSPHEREDB_DATABASE_USER}'"
      exit 1
    fi
  fi
}

# create database
#
create_database() {

  local database_name="${VSPHEREDB_DATABASE_NAME}"
  local modules_directory="${ICINGAWEB_MODULES_DIRECTORY}/vspheredb"

  # check if database already created ...
  #
  query="SHOW DATABASES LIKE '${VSPHEREDB_DATABASE_NAME}'"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #

    log_info "      initializing vspheredb databases"
    (
      echo "CREATE DATABASE IF NOT EXISTS ${VSPHEREDB_DATABASE_NAME} DEFAULT CHARACTER SET 'utf8mb4' COLLATE utf8mb4_bin;"
      echo "GRANT SELECT, INSERT, UPDATE, CREATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE, ALTER ON ${VSPHEREDB_DATABASE_NAME}.* TO '${VSPHEREDB_DATABASE_USER}'@'%';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "can't create database '${VSPHEREDB_DATABASE_NAME}'"
      exit 1
    fi
  fi
}

# create database schema
#

create_schema() {

  local database_name="${VSPHEREDB_DATABASE_NAME}"
  local modules_directory="${ICINGAWEB_MODULES_DIRECTORY}/vspheredb"

  # check if database already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = '${database_name}' limit 1;"

  database_status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w )

  if [[ ${database_status} -eq 0 ]]
  then

    SCHEMA_FILE="${modules_directory}/schema/mysql.sql"

    if [[ -f ${SCHEMA_FILE} ]]
    then
      log_info "      import database schema"

      mysql ${MYSQL_OPTS} --force ${database_name} < ${SCHEMA_FILE}

      if [[ $? -eq 0 ]]
      then

        log_info "      import database migrations"
        for f in $(ls -1 ${modules_directory}/schema/mysql-migrations/*.sql)
        do
          log_info "      apply database migration from '$(basename ${f})'"

          mysql ${MYSQL_OPTS} --force ${database_name}  < ${f} 2> /dev/null

          if [[ $? -gt 0 ]]
          then
            log_error "      database migration failed"
            exit 1
          fi
        done

      else
        log_error "can't insert the Database Schema"
        exit 1
      fi
    else
      log_warn "missing schema file"
    fi
  fi
}

configure() {

  local vspheredb="${ICINGAWEB_MODULES_DIRECTORY}/vspheredb"

  # icingaweb vspheredb
  #
  if [[ -d ${vspheredb} ]]
  then
    #log_info "configure vspheredb"

    create_user

    create_database

    create_schema

    log_info "    create config files for icingaweb"

    if [[ $(grep -c "vspheredb]" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[vspheredb]
type       = "db"
db         = "mysql"
host       = "${MYSQL_HOST}"
port       = "${MYSQL_PORT}"
dbname     = "${VSPHEREDB_DATABASE_NAME}"
username   = "${VSPHEREDB_DATABASE_USER}"
password   = "${VSPHEREDB_DATABASE_PASS}"
charset    = "utf8mb4"

EOF
    fi

    [[ -d /etc/icingaweb2/modules/vspheredb ]] || mkdir -p /etc/icingaweb2/modules/vspheredb

    #
    #
    if [[ ! -f /etc/icingaweb2/modules/vspheredb/config.ini ]]
    then
      cat << EOF > /etc/icingaweb2/modules/vspheredb/config.ini
[db]
resource = "vspheredb"
EOF
    fi
  fi

  # enable module
  #
  enable_module vspheredb

  # icingacli vspheredb task initialize --serverId 1
  # icingacli vspheredb daemon run --trace --debug
  # icingacli vspheredb task sync --trace --debug --vCenterId 1

  nohup /init/runtime/watch_vspheredb.sh > /dev/stdout 2>&1 &


  # TODO check running process and restart them if needed
  #
  #

  # this produce the following 'error'
  # S erver for vCenterID=1 failed, will try again in 30 seconds
  #  Server for vCenterID=2 failed, will try again in 30 seconds
  # and ist so not usable
  # see issue https://github.com/Icinga/icingaweb2-module-vspheredb/issues/80
  #
  #log_info "      - run background deamon"
  #nohup /usr/bin/icingacli \
  #  vspheredb \
  #  daemon \
  #  run > /proc/self/fd/2 2>&1 &

}

check
configure
