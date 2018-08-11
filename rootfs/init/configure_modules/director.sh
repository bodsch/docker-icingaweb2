

[[ -z "${MYSQL_OPTS}" ]] && return

if [[ "${ICINGAWEB_DIRECTOR}" = "false" ]]
then
  log_info "disable director support"

  /usr/bin/icingacli module disable director
  return
fi


director_create_database() {

    # check if database already created ...
    #
    query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = 'director' limit 1;"

    director_status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w )

    if [[ ${director_status} -eq 0 ]]
    then
      # Database isn't created
      # well, i do my job ...
      #
      log_info "  - initializing databases"

      (
        echo "CREATE DATABASE IF NOT EXISTS director DEFAULT CHARACTER SET 'utf8';"
        echo "GRANT ALL ON director.* TO 'director'@'%' IDENTIFIED BY '${MYSQL_ICINGAWEB2_PASSWORD}';"
        echo "quit"
      ) | mysql ${MYSQL_OPTS}

      SCHEMA_FILE="${director}/schema/mysql.sql"

      if [[ -f ${SCHEMA_FILE} ]]
      then
        mysql ${MYSQL_OPTS} --force  director < ${SCHEMA_FILE}

        if [ $? -gt 0 ]
        then
          log_error "can't insert the director Database Schema"
          exit 1
        fi
      fi

    fi
}


configure_icinga_director() {

  local director="/usr/share/webapps/icingaweb2/modules/director"

  # icingaweb director
  #
  if [[ -d ${director} ]]
  then

    log_info "configure director"

    director_create_database

    log_info "  - create config files for icingaweb"

    if [[ $(grep -c "director]" /etc/icingaweb2/resources.ini) -eq 0 ]]
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

    # we must wait for icinha2-master
    #
    if [[ ! -f /etc/icingaweb2/modules/director/kickstart.ini ]]
    then
      cat << EOF > /etc/icingaweb2/modules/director/kickstart.ini
[config]
endpoint = ${ICINGA2_MASTER}
host     = ${ICINGA2_MASTER}
port     = ${ICINGA2_API_PORT}
username = ${ICINGA2_CMD_API_USER}
password = ${ICINGA2_CMD_API_PASS}
EOF
    fi

    set +e
    set +u

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
      log_info "  - migration pending '${code}' (${migration_status})"

      if [[ ${migration_status} -eq 0 ]]
      then
        log_info "  - icingacli director migration run"
        status=$(icingacli director migration run --verbose)
        #log_info "    ${status}"
      fi

      code=$(icingacli director kickstart required --verbose)
      kickstart_status="${?}"

      log_info "  - kickstart required '${code}' (${kickstart_status})"

      if [[ ${kickstart_status} -eq 1 ]]
      then
        break
      fi

      if [[ ${kickstart_status} -eq 0 ]]
      then
        log_info "  - icingacli director kickstart run"
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

}

configure_icinga_director

# EOF
