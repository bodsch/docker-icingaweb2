#!/bin/bash
#
#

CERTS_FILE=${CERTS_FILE:-"/etc/ssl/certs/ca-certificates.crt"}

. /init/output.sh
. /init/common.sh

log_info "  x509"

ICINGAWEB_X509=${ICINGAWEB_X509:-"true"}

X509_DATABASE_USER=${X509_DATABASE_USER:-"x509"}
X509_DATABASE_PASS=${X509_DATABASE_PASS:-"x509"}
X509_DATABASE_NAME=${X509_DATABASE_NAME:-"x509"}
MYSQL_UOPTS="--host=${MYSQL_HOST} --user=${X509_DATABASE_USER} --password=${X509_DATABASE_PASS} --port=${MYSQL_PORT}"

check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1

  if [[ "${ICINGAWEB_X509}" = "false" ]]
  then
    log_info "    x509 support is disabled"

    disable_module x509
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/x509"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then
    create_user

    create_database

    create_schema

    [[ -d /etc/icingaweb2/modules/x509 ]] || mkdir -p /etc/icingaweb2/modules/x509

    log_info "    create config files for icingaweb"

    if [[ $(grep -c "x509" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[x509]
type       = "db"
db         = "mysql"
host       = "${MYSQL_HOST}"
port       = "${MYSQL_PORT}"
dbname     = "${X509_DATABASE_NAME}"
username   = "${X509_DATABASE_USER}"
password   = "${X509_DATABASE_PASS}"
charset    = "utf8mb4"

EOF
    fi

    if [[ ! -f /etc/icingaweb2/modules/x509/config.ini ]]
    then
      cat << EOF > /etc/icingaweb2/modules/x509/config.ini

[backend]
resource = "x509"
EOF
    fi

    enable_module x509

    if [[ -f ${CERTS_FILE} ]]
    then
      log_info "    import ca-certificates.crt"
      /usr/bin/icingacli x509 import --verbose --file ${CERTS_FILE}
    else
      log_error "    no certificate file found"
    fi

    #log_info "    enable module"
    #/usr/bin/icingacli module enable x509

    touch /etc/icingaweb2/modules/x509/jobs.ini

    if [[ -d /init/custom.d/x509 ]] && [[ -f /init/custom.d/x509/jobs.ini ]]
    then
      cat /init/custom.d/x509/jobs.ini >> /etc/icingaweb2/modules/x509/jobs.ini
    fi

    #log_info "    run background deamon"
    /init/runtime/watch_x509.sh > /dev/stdout 2>&1 &

    sleep 2s

    log_info "    run background deamon"
    /usr/bin/icingacli \
      x509 \
      jobs \
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

    log_info "    initializing x509 db user"
    (
      echo "CREATE USER '${X509_DATABASE_USER}'@'%' IDENTIFIED BY '${X509_DATABASE_PASS}';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "failed to create user: '${X509_DATABASE_USER}'"
      exit 1
    fi
  fi
}

# create database
#
create_database() {


  local database_name="${X509_DATABASE_NAME}"
  local modules_directory="/usr/share/icingaweb2/modules/x509"

  # check if database already created ...
  #
  query="SHOW DATABASES LIKE '${database_name}'"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #

    log_info "    initializing x509 databases"
    (
      echo "CREATE DATABASE IF NOT EXISTS ${database_name} DEFAULT CHARACTER SET 'utf8mb4' COLLATE utf8mb4_bin;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO '${X509_DATABASE_USER}'@'%';"
      echo "FLUSH PRIVILEGES;"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "can't create database '${database_name}'"
      exit 1
    fi
  fi
}

# create web database schema
#
create_schema() {


  local database_name="${X509_DATABASE_NAME}"
  local modules_directory="/usr/share/icingaweb2/modules/x509"


  # check if database scheme is already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = \"${database_name}\" limit 1;"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then

    SCHEMA_FILE="${modules_directory}/etc/schema/mysql.schema.sql"

    if [[ -f ${SCHEMA_FILE} ]]
    then
      log_info "    import database schema"

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
