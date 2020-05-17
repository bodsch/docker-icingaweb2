
# wait for mariadb / mysql
#
wait_for_database() {

  log_info "checking DB and DNS prerequisites for '${MYSQL_HOST}'"

  . /init/wait_for/dns.sh

  log_info "checking port availibility for '${MYSQL_HOST}'"

  . /init/wait_for/port.sh

  wait_for_dns ${MYSQL_HOST}
  wait_for_port ${MYSQL_HOST} ${MYSQL_PORT} 15

  log_info "waiting for script responses on '${MYSQL_HOST}'"

  sleep 2s

  RETRY=10

  # must start initdb and do other jobs well
  #
  until [[ ${RETRY} -le 0 ]]
  do
    #  mysql ${MYSQL_OPTS} --execute="select 1 from mysql.user limit 1" > /dev/null
    mysql ${MYSQL_OPTS} --execute="SELECT USER(),CURRENT_USER();" > /dev/null


    [[ $? -eq 0 ]] && break

    log_info "wait for the database for her initdb and all other jobs"
    sleep 13s
    RETRY=$(expr ${RETRY} - 1)
  done

  sleep 2s
}

wait_for_database
