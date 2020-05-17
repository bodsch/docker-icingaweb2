#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  director"

ICINGA2_DIRECTOR_HOST=${ICINGA2_DIRECTOR_HOST:-${ICINGA2_MASTER}}
MYSQL_DIRECTOR_USER=${MYSQL_DIRECTOR_USER:-"director"}
MYSQL_DIRECTOR_PASS=${MYSQL_DIRECTOR_PASS:-"director"}
MYSQL_DIRECTOR_NAME=${MYSQL_DIRECTOR_NAME:-"director"}
MYSQL_UOPTS="--host=${MYSQL_HOST} --user=${MYSQL_DIRECTOR_USER} --password=${MYSQL_DIRECTOR_PASS} --port=${MYSQL_PORT}"

check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1

  if [[ "${ICINGAWEB_DIRECTOR}" = "false" ]]
  then
    log_info "    director support is disabled"

    disable_module director
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

    log_info "      initializing director user"
    (
      echo "create user '${MYSQL_DIRECTOR_USER}'@'%' IDENTIFIED BY '${MYSQL_DIRECTOR_PASS}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "failed to create user: '${MYSQL_DIRECTOR_USER}'"
      exit 1
    fi
  fi
}


# create database
#
create_database() {

  # check if database already created ...
  #
  query="SHOW DATABASES LIKE '${MYSQL_DIRECTOR_NAME}'"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #

    log_info "      initializing director databases"
    (
      echo "CREATE DATABASE IF NOT EXISTS ${MYSQL_DIRECTOR_NAME} DEFAULT CHARACTER SET 'utf8';"
      echo "GRANT SELECT, INSERT, UPDATE, CREATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE, ALTER ON ${MYSQL_DIRECTOR_NAME}.* TO '${MYSQL_DIRECTOR_USER}'@'%';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "can't create database '${MYSQL_DIRECTOR_NAME}'"
      exit 1
    fi
  fi
}


# create web database schema
#
create_schema() {

  # check if database scheme is already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = \"${MYSQL_DIRECTOR_NAME}\" limit 1;"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  local database_name="${MYSQL_DIRECTOR_NAME}"
  local modules_directory="${ICINGAWEB_MODULES_DIRECTORY}/director"

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

configure() {

  check

  local director="${ICINGAWEB_MODULES_DIRECTORY}/director"

  # icingaweb director
  #
  if [[ -d ${director} ]]
  then

    log_info "    configure director"

    create_user

    create_database

    create_schema

    enable_module director

    log_info "    create config files for icingaweb"

    if [[ $(grep -c "director]" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[director]
type       = "db"
db         = "mysql"
charset    = "utf8"
host       = "${MYSQL_HOST}"
port       = "${MYSQL_PORT}"
dbname     = "${MYSQL_DIRECTOR_NAME}"
username   = "${MYSQL_DIRECTOR_USER}"
password   = "${MYSQL_DIRECTOR_PASS}"

EOF
    fi

    # we must wait for icinha2-master
    #
    if [[ ! -f /etc/icingaweb2/modules/director/kickstart.ini ]]
    then
      cat << EOF > /etc/icingaweb2/modules/director/kickstart.ini
[config]
endpoint = ${ICINGA2_MASTER}
host     = ${ICINGA2_DIRECTOR_HOST}
port     = ${ICINGA2_API_PORT}
username = ${ICINGA2_CMD_API_USER}
password = ${ICINGA2_CMD_API_PASS}
EOF
    fi

    set +e
    set +u

    log_info "    start director migration and kickstart"

    retry=4
    migration_status=
    kickstart_status=

    until [[ ${retry} -le 0 ]]
    do
      migration_status=
      kickstart_status=

      status=$(icingacli director endpoint exists ${ICINGA2_MASTER})
      #log_info "    ${status}"

      code=$(icingacli director migration pending --verbose)
      migration_status="${?}"
      #log_info "    migration pending" # '${code}' (${migration_status})"

      if [[ ${migration_status} -eq 0 ]]
      then
        #log_info "    icingacli director migration run"
        status=$(icingacli director migration run --verbose)
        #log_info "    ${status}"
      fi

      code=$(icingacli director kickstart required --verbose)
      kickstart_status="${?}"

      #log_info "    kickstart required" # '${code}' (${kickstart_status})"

      if [[ ${kickstart_status} -eq 1 ]]
      then
        break
      fi

      if [[ ${kickstart_status} -eq 0 ]]
      then
        #log_info "    icingacli director kickstart run"
        status=$(icingacli director kickstart run --verbose)
        #log_info "    ${status}"
      fi

      retry=$(expr ${retry} - 1)
    done

    status=$(icingacli director config render)
    #log_info "    ${status}"
    status=$(icingacli director config deploy)
    #log_info "    ${status}"
  fi

  log_info "    run background deamon"
  /usr/bin/icingacli \
    director \
    daemon \
    run &

}

configure

# EOF
