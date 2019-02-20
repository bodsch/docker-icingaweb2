#!/bin/bash
#
#

CERTS_FILE=${CERTS_FILE:-"/etc/ssl/certs/ca-certificates.crt"}

. /init/output.sh

log_info "  - x509"

DATABASE_X509_PASSWORD="x509"

check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1
}

configure() {

  local module_directory="/usr/share/webapps/icingaweb2/modules/x509"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then
    create_database

    [[ -d /etc/icingaweb2/modules/x509 ]] || mkdir -p /etc/icingaweb2/modules/x509

    log_info "      - create config files for icingaweb"

    if [[ $(grep -c "x509" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[x509]
type       = "db"
db         = "mysql"
host       = "${MYSQL_HOST}"
port       = 3306
dbname     = "x509"
username   = "x509"
password   = "${DATABASE_X509_PASSWORD}"
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

    if [[ -f ${CERTS_FILE} ]]
    then
      log_info "      - import ca-certificates.crt"
      /usr/bin/icingacli x509 import --file ${CERTS_FILE} > /dev/null
    fi

    log_info "      - enable module"
    /usr/bin/icingacli module enable x509

    touch /etc/icingaweb2/modules/x509/jobs.ini

    #log_info "      - run background deamon"
    /init/runtime/watch_x509.sh > /dev/stdout 2>&1 &

    sleep 2s

    if [[ -d /init/custom.d/x509 ]] && [[ -f /init/custom.d/x509/jobs.ini ]]
    then
      cat /init/custom.d/x509/jobs.ini >> /etc/icingaweb2/modules/x509/jobs.ini
    fi

    log_info "      - run background deamon"
    /usr/bin/icingacli \
      x509 \
      jobs \
      run &

  fi
}

create_database() {

  local database_name='x509'
  local modules_directory="/usr/share/webapps/icingaweb2/modules/x509"

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
      echo "--- create user 'x509'@'%' IDENTIFIED BY '${DATABASE_X509_PASSWORD}';"
      echo "CREATE DATABASE IF NOT EXISTS ${database_name} DEFAULT CHARACTER SET 'utf8mb4' COLLATE utf8mb4_bin;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'x509'@'%' IDENTIFIED BY '${DATABASE_X509_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'x509'@'$(hostname -i)' IDENTIFIED BY '${DATABASE_X509_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'x509'@'$(hostname -s)' IDENTIFIED BY '${DATABASE_X509_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'x509'@'$(hostname -f)' IDENTIFIED BY '${DATABASE_X509_PASSWORD}';"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    SCHEMA_FILE="${modules_directory}/etc/schema/mysql.schema.sql"

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
