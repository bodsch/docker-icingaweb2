
MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}

IDO_DATABASE_NAME=${IDO_DATABASE_NAME:-"icinga2core"}
IDO_USER=${IDO_USER:-"icinga2"}
IDO_PASSWORD=${IDO_PASSWORD:-"icinga2"}
IDO_COLLATION=${IDO_COLLATION:-"latin1"}
WEB_DATABASE_USER=${WEB_DATABASE_USER:-"icingaweb2"}
WEB_DATABASE_PASS=${WEB_DATABASE_PASS:-"icingaweb2"}
WEB_DATABASE_NAME=${WEB_DATABASE_NAME:-"icingaweb2"}
MYSQL_UOPTS="--host=${MYSQL_HOST} --user=${WEB_DATABASE_USER} --password=${WEB_DATABASE_PASS} --port=${MYSQL_PORT}"


# -------------------------------------------------------------------------------------------------

[[ -z "${MYSQL_OPTS}" ]] && return
[[ -z "${MYSQL_HOST}" ]] && return


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

    log_info "create User ignore Errors if already exists"
    (
      echo "create user '${WEB_DATABASE_USER}'@'%' IDENTIFIED BY '${WEB_DATABASE_PASS}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "failed to create user: '${IDO_USER}'"
      exit 1
    fi
  fi
}


# create web database schema
#
create_database() {

  # check if database already created ...
  #
  query="SHOW DATABASES LIKE '${WEB_DATABASE_NAME}'"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #
    log_info "create database '${WEB_DATABASE_NAME}' with user and grants for '${WEB_DATABASE_USER}'"
    (
      echo "CREATE DATABASE IF NOT EXISTS ${WEB_DATABASE_NAME} DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
      echo "CREATE DATABASE IF NOT EXISTS ${WEB_DATABASE_NAME};"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${WEB_DATABASE_NAME}.* TO '${WEB_DATABASE_USER}'@'%';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
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

  mysql ${MYSQL_OPTS} --force ${WEB_DATABASE_NAME}  < /usr/share/icingaweb2/etc/schema/mysql.schema.sql

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

  create_user
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
port      = "${MYSQL_PORT}"
dbname    = "${WEB_DATABASE_NAME}"
username  = "${WEB_DATABASE_USER}"
password  = "${WEB_DATABASE_PASS}"
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
port      = "${MYSQL_PORT}"
dbname    = "${IDO_DATABASE_NAME}"
username  = "${IDO_USER}"
password  = "${IDO_PASSWORD}"
charset   = "${IDO_COLLATION}"
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
