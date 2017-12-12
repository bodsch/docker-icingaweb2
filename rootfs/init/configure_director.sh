

if [ -z "${MYSQL_OPTS}" ]
then
  return
fi

configure_icinga_director() {

  local director="/usr/share/webapps/icingaweb2/modules/director"

  # icingaweb director
  #
  if [ -d ${director} ]
  then

    # check if database already created ...
    #
    query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = 'director' limit 1;"

    director_status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w )

    if [ ${director_status} -eq 0 ]
    then
      # Database isn't created
      # well, i do my job ...
      #
      echo " [i] director: initializing databases"

      (
        echo "CREATE DATABASE IF NOT EXISTS director DEFAULT CHARACTER SET 'utf8';"
        echo "GRANT ALL ON director.* TO 'director'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
        echo "quit"
      ) | mysql ${MYSQL_OPTS}

      SCHEMA_FILE="${director}/schema/mysql.sql"

      if [ -f ${SCHEMA_FILE} ]
      then
        mysql ${MYSQL_OPTS} --force  director < ${SCHEMA_FILE}

        if [ $? -gt 0 ]
        then
          echo " [E] can't insert the director Database Schema"
          exit 1
        fi
      fi

    fi

    echo " [i] director: configure director for icingaweb"

    if [ $(grep -c "director]" /etc/icingaweb2/resources.ini) -eq 0 ]
    then
      cat << EOF >> /etc/icingaweb2/resources.ini

[director]
type       = "db"
db         = "mysql"
charset    = "utf8"
host       = "${MYSQL_HOST}"
port       = "3306"
dbname     = "director"
username   = "director"
password   = "${MYSQL_ICINGAWEB2_PASSWORD}"

EOF
    fi
  fi

}

configure_icinga_director

# EOF
