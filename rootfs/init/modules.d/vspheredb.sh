#!/bin/bash
#
#

. /init/output.sh

log_info "  - vspheredb"

DATABASE_VSPHEREDB_PASSWORD="vspheredb"

check() {

  [[ -z "${MYSQL_OPTS}" ]] && exit 1

  if [[ "${ICINGAWEB_DIRECTOR}" = "false" ]]
  then
    log_info "    director support is disabled"

    /usr/bin/icingacli module disable vspheredb
    exit 0
  fi
}

create_database() {

  local database_name='vspheredb'
  local modules_directory="/usr/share/webapps/icingaweb2/modules/vspheredb"

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
      echo "--- create user 'director'@'%' IDENTIFIED BY '${DATABASE_VSPHEREDB_PASSWORD}';"
      echo "CREATE DATABASE IF NOT EXISTS ${database_name} DEFAULT CHARACTER SET 'utf8mb4' COLLATE utf8mb4_bin;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'vspheredb'@'%' IDENTIFIED BY '${DATABASE_VSPHEREDB_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'vspheredb'@'$(hostname -i)' IDENTIFIED BY '${DATABASE_VSPHEREDB_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'vspheredb'@'$(hostname -s)' IDENTIFIED BY '${DATABASE_VSPHEREDB_PASSWORD}';"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${database_name}.* TO 'vspheredb'@'$(hostname -f)' IDENTIFIED BY '${DATABASE_VSPHEREDB_PASSWORD}';"
      echo "quit"
    ) | mysql ${MYSQL_OPTS}

    SCHEMA_FILE="${modules_directory}/schema/mysql.sql"

    if [[ -f ${SCHEMA_FILE} ]]
    then
      log_info "      - import database schema"

      mysql ${MYSQL_OPTS} --force ${database_name} < ${SCHEMA_FILE}

      if [[ $? -gt 0 ]]
      then
        log_error "    can't insert the Database Schema"
        exit 1
      fi
    else
      log_warn "    missing schema file"
    fi
  fi
}

configure() {

  #check

  #react="/usr/share/webapps/icingaweb2/modules/reactbundle"
  #
  #if [[ ! -e /usr/bin/composer ]]
  #then
  #  log_error "missing composer!"
  #  log_debug "read: https://gist.github.com/bodsch/4ea55240d7c4b0706d8504eba6b975fc"
  #
  #  exit 1
  #else
  #  cd ${react}
  #
  #  /usr/bin/composer install
  #fi

  local vspheredb="/usr/share/webapps/icingaweb2/modules/vspheredb"

  # icingaweb vspheredb
  #
  if [[ -d ${vspheredb} ]]
  then
    #log_info "configure vspheredb"

    create_database

    log_info "      - create config files for icingaweb"

    if [[ $(grep -c "vspheredb]" /etc/icingaweb2/resources.ini) -eq 0 ]]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[vspheredb]
type       = "db"
db         = "mysql"
host       = "${MYSQL_HOST}"
port       = 3306
dbname     = "vspheredb"
username   = "vspheredb"
password   = "${DATABASE_VSPHEREDB_PASSWORD}"
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
  log_info "      - enable module"
  /usr/bin/icingacli module enable vspheredb

  # icingacli vspheredb task initialize --serverId 1
  # icingacli vspheredb daemon run --trace --debug
  # icingacli vspheredb task sync --trace --debug --vCenterId 1


  # TODO check running process and restart them if needed
  #
  log_info "      - run background deamon"
  nohup /usr/bin/icingacli \
    vspheredb \
    daemon \
    run > /proc/self/fd/2 2>&1 &

}

check
configure
