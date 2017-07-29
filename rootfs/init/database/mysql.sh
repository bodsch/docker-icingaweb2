
MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}

IDO_DATABASE_NAME=${IDO_DATABASE_NAME:-"icinga2core"}
WEB_DATABASE_NAME=${WEB_DATABASE_NAME:-"icingaweb2"}

# -------------------------------------------------------------------------------------------------

if [ -z "${MYSQL_OPTS}" ]
then
  return
fi

wait_for_database() {

  RETRY=15

  # wait for database
  #
  until [ ${RETRY} -le 0 ]
  do
    nc ${MYSQL_HOST} ${MYSQL_PORT} < /dev/null > /dev/null

    [ $? -eq 0 ] && break

    echo " [i] Waiting for database to come up"

    sleep 5s
    RETRY=$(expr ${RETRY} - 1)
  done

  if [ $RETRY -le 0 ]
  then
    echo " [E] Could not connect to Database on ${MYSQL_HOST}:${MYSQL_PORT}"
    exit 1
  fi

  RETRY=10

  # must start initdb and do other jobs well
  #
  until [ ${RETRY} -le 0 ]
  do
    mysql ${MYSQL_OPTS} --execute="select 1 from mysql.user limit 1" > /dev/null

    [ $? -eq 0 ] && break

    echo " [i] wait for the database for her initdb and all other jobs"
    sleep 5s
    RETRY=$(expr ${RETRY} - 1)
  done

}

create_database() {

  # create user - when they NOT exists
  query="select host, user, password from mysql.user where user = '${WEB_DATABASE_NAME}';"
  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w)

  if [ ${status} -eq 0 ]
  then
    echo " [i] create database '${WEB_DATABASE_NAME}' with user and grants for 'icingaweb2'"
    (
      echo "--- create user 'icingaweb2'@'%' IDENTIFIED BY '${IDO_PASSWORD}';"
      echo "CREATE DATABASE IF NOT EXISTS ${WEB_DATABASE_NAME} DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE utf8_general_ci;"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${WEB_DATABASE_NAME}.* TO 'icingaweb2'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [ $? -eq 1 ]
    then
      echo " [E] can't create database '${WEB_DATABASE_NAME}'"
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

  echo " [i] create database schema"

  mysql ${MYSQL_OPTS} --force ${WEB_DATABASE_NAME}  < /usr/share/webapps/icingaweb2/etc/schema/mysql.schema.sql

  if [ $? -gt 0 ]
  then
    echo " [E] can't insert the icingaweb2 database schema"
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
  if [ ${status} -eq 0 ]
  then
    # the database is fresh created
    create_database_schema
  elif ( [ ${status} -gt 0 ] && [ ${status} -lt 5 ] )
  then
    # between 1 and 5, the creation of database was wrong
    drop_database_schema
    sleep 2s
    create_database_schema
  else
    echo " [W] we found ${status} tables into schema ${WEB_DATABASE_NAME}"
    exit 1
  fi
}


create_resource_file() {

  if [ $(grep -c "icingaweb_db]" /etc/icingaweb2/resources.ini) -eq 0 ]
  then
    cat << EOF >> /etc/icingaweb2/resources.ini

[icingaweb_db]
type                = "db"
db                  = "mysql"
host                = "${MYSQL_HOST}"
port                = "3306"
dbname              = "icingaweb2"
username            = "icingaweb2"
password            = "${MYSQL_ICINGAWEB2_PASSWORD}"
prefix              = "icingaweb_"

EOF
  fi

  if [ $(grep -c "icinga_ido]" /etc/icingaweb2/resources.ini) -eq 0 ]
  then
    if ( [ ! -z ${IDO_PASSWORD} ] || [ ! -z ${IDO_DATABASE_NAME} ] )
    then

      cat << EOF >> /etc/icingaweb2/resources.ini

[icinga_ido]
type                = "db"
db                  = "mysql"
host                = "${MYSQL_HOST}"
port                = "3306"
dbname              = "${IDO_DATABASE_NAME}"
username            = "icinga2"
password            = "${IDO_PASSWORD}"

EOF
    else
      echo " [i] IDO_PASSWORD isn't set."
      echo " [i] disable IDO Access for Icingaweb"
    fi
  fi
}


wait_for_database

configure_database

create_resource_file

# EOF

