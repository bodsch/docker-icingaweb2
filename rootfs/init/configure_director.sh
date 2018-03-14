

[[ -z "${MYSQL_OPTS}" ]] && return

configure_icinga_director() {

  local director="/usr/share/webapps/icingaweb2/modules/director"

  # icingaweb director
  #
  if [[ -d ${director} ]]
  then

    # check if database already created ...
    #
    query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = 'director' limit 1;"

    director_status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w )

    if [[ ${director_status} -eq 0 ]]
    then
      # Database isn't created
      # well, i do my job ...
      #
      log_info "director: initializing databases"

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

    log_info "director: configure director for icingaweb"

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

    if [[ ! -f /etc/icingaweb2/modules/director/kickstart.ini ]]
    then
      cat << EOF >> /etc/icingaweb2/modules/director/kickstart.ini
[config]
endpoint = ${ICINGA2_MASTER}
; host = ${ICINGA2_MASTER}
; port = ${ICINGA2_API_PORT}
username = ${ICINGA2_CMD_API_USER}
password = ${ICINGA2_CMD_API_PASS}
EOF

      icingacli director migration pending --verbose
      status="${?}"
      log_info "director: migration pending  ${status}"
      if [[ ${status} -eq 0 ]]
      then
        log_info "director: icingacli director migration run"
        icingacli director migration run --verbose
      fi

      icingacli director kickstart required --verbose
      status="${?}"
      log_info "director: kickstart required  ${status}"
      if [[ ${status} -eq 0 ]]
      then
        log_info "director: icingacli director kickstart run"
        icingacli director kickstart run --verbose
      fi
    fi
  fi

}

configure_icinga_director

# EOF
