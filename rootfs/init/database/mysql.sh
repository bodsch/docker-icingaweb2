
MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}

IDO_DATABASE_NAME=${IDO_DATABASE_NAME:-"icinga2core"}
WEB_DATABASE_NAME=${WEB_DATABASE_NAME:-"icingaweb2"}

# -------------------------------------------------------------------------------------------------

[[ -z "${MYSQL_OPTS}" ]] && return
[[ -z "${MYSQL_HOST}" ]] && return


create_database() {

  # create user - when they NOT exists
  query="select host, user, password from mysql.user where user = '${WEB_DATABASE_NAME}';"
  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w)

  if [[ ${status} -eq 0 ]]
  then
    log_info "create database '${WEB_DATABASE_NAME}' with user and grants for 'icingaweb2'"
    (
      echo "--- create user 'icingaweb2'@'%' IDENTIFIED BY '${IDO_PASSWORD}';"
      echo "--- CREATE DATABASE IF NOT EXISTS ${WEB_DATABASE_NAME} DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
      echo "CREATE DATABASE IF NOT EXISTS ${WEB_DATABASE_NAME};"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${WEB_DATABASE_NAME}.* TO 'icingaweb2'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [ $? -eq 1 ]
    then
      log_error "can't create database '${WEB_DATABASE_NAME}'"
      exit 1
    fi
  fi

  # check user
  #
  # query="select host, user, password from mysql.user where user = '${WEB_DATABASE_NAME}';"
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = \"${WEB_DATABASE_NAME}\";"
  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | grep -v host | wc -l)

  return ${status}
}


create_database_schema() {

  log_info "create database schema"

  mysql ${MYSQL_OPTS} --force ${WEB_DATABASE_NAME}  < /usr/share/webapps/icingaweb2/etc/schema/mysql.schema.sql

  if [ $? -gt 0 ]
  then
    log_error "can't insert the icingaweb2 database schema"
    exit 1
  fi
}


drop_database_schema() {

  query="drop database ${WEB_DATABASE_NAME};"
  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w)
}


configure_database() {

  create_database
  status=$?

  # if ${status} == 0,
  #
  if [[ ${status} -eq 0 ]]
  then
    # the database is fresh created
    create_database_schema
  elif ( [[ ${status} -gt 0 ]] && [[ ${status} -lt 5 ]] )
  then
    # between 1 and 5, the creation of database was wrong
    drop_database_schema
    sleep 2s
    create_database_schema
  fi
}


create_resource_file() {

  if [[ $(grep -c "icingaweb_db]" /etc/icingaweb2/resources.ini) -eq 0 ]]
  then
    cat << EOF >> /etc/icingaweb2/resources.ini

[icingaweb_db]
type      = "db"
db        = "mysql"
host      = "${MYSQL_HOST}"
port      = "3306"
dbname    = "icingaweb2"
username  = "icingaweb2"
password  = "${MYSQL_ICINGAWEB2_PASSWORD}"
prefix    = "icingaweb_"
charset   = "utf8"

EOF
  fi

  if [[ $(grep -c "icinga_ido]" /etc/icingaweb2/resources.ini) -eq 0 ]]
  then
    if ( [[ ! -z ${IDO_PASSWORD} ]] || [[ ! -z ${IDO_DATABASE_NAME} ]] )
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[icinga_ido]
type      = "db"
db        = "mysql"
host      = "${MYSQL_HOST}"
port      = "3306"
dbname    = "${IDO_DATABASE_NAME}"
username  = "icinga2"
password  = "${IDO_PASSWORD}"
charset   = "utf8"
EOF
    else
      log_warn "IDO_PASSWORD isn't set."
      log_warn "disable IDO Access for Icingaweb"
    fi
  fi
}

. /init/wait_for/mysql.sh

configure_database

create_resource_file

# EOF

