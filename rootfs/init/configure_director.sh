

[ -z {MYSQL_OPTS} ] && return

configureIcingaDirector() {

  local director="/usr/share/webapps/icingaweb2/modules/director"

  # icingaweb director
  #
  if [ -d ${director} ]
  then

    echo " [i] configure Icingaweb2 Director"

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

      if [ $(grep -c "director]" /etc/icingaweb2/resources.ini) -eq 0 ]
      then
        cat << EOF >> /etc/icingaweb2/resources.ini

[director]
type                = "db"
db                  = "mysql"
charset             = "utf8"
host                = "${MYSQL_HOST}"
port                = "3306"
dbname              = "director"
username            = "director"
password            = "${MYSQL_ICINGAWEB2_PASSWORD}"

EOF
      fi
    fi
  fi
}

configureIcingaDirector

# EOF
