#!/bin/bash

# watch database to detect configured vcenter instances
# run 'icingacli vspheredb task initialize ...' and
# 'icingacli vspheredb task sync' manually
#

. /init/output.sh
. /init/ini_parser.sh

monitored_directory="/etc/icingaweb2/modules/vspheredb"
hostname_f=$(hostname -f)

database_cnf="${monitored_directory}/.my.cnf"

finish() {

  rv=$?
  echo -e "\033[38;5;202m\033[1mexit with signal '${rv}'\033[0m"

  pids=$(ps aux | grep -v grep | grep "Icinga::vSphereDB::sync" | awk '{print $1}')

  for p in ${pids}
  do
    kill -15 ${p}
    rm -f "/tmp/vspheredb_*_sync.lock"
  done

  exit $rv
}

trap finish KILL # SIGINT SIGTERM INT TERM EXIT

clean_sync_tasks() {

  local pids=${1}
  local db_data=${2}

  arr_pids=($pids)
  arr_dba=($db_data)

  for i in ${arr_dba[@]}
  do
    # log_debug "search ${i}"

    pid=$(ps aux | grep -v grep | grep $i | awk '{print $1}')

    if [[ " ${arr_pids[@]} " =~ " ${pid} " ]]
    then
      for x in ${!arr_pids[@]}
      do
        if [ "${arr_pids[$x]}" == "${pid}" ]
        then
          unset arr_pids[$x]
        fi
      done
    fi
  done

  for i in ${arr_pids[@]}
  do
    missing=$(ps ax -o pid,args | grep -v grep | grep ${i} | cut -d "(" -f2 | cut -d ")" -f1)
    log_info "remove sync task for ${missing} (pid: ${i})"
    kill -15 ${i}
  done

#set +x
}


create_secrets_file() {

  if [[ ! -f "${database_cnf}" ]]
  then
    # log_info "        read database resource ..."
    cfg_parser '/etc/icingaweb2/resources.ini'
    cfg_section_vspheredb

    dba_name="${dbname}"
    dba_host="${host}"
    dba_username="${username}"
    dba_password="${password}"

    cat << EOF >> ${database_cnf}
[client]
host=${dba_host}
database=${dba_name}
user=${dba_username}
password=${dba_password}
EOF

  fi
}


vspheredb_handler() {

  while true
  do
    # clean up old sync tasks
    #
    pids=$(ps aux | grep -v grep | grep "Icinga::vSphereDB::sync" | awk '{print $1}')

    data=$(mysql \
          --defaults-file=${database_cnf} \
          --skip-column-names \
          --silent \
          "--execute=SELECT JSON_OBJECT( 'host', host ) from vcenter_server;")

    if ( [[ ! -z "${pids}" ]] || [[ ! -z "${data}" ]] ) && ( [[ $(echo "${pids}" | wc -l) -gt $(echo "${data}" | jq '.host' | wc -l) ]] )
    then
      # log_debug "data: '${data}' $(echo "${data}" | jq '.host' | wc -l) "

      clean_sync_tasks "${pids}" "${data}"
    fi

    # get data from database
    #
    while read -r line
    do
      id=$(echo "${line}" | awk '{print $1}')
      vcenter_id=$(echo "${line}" | awk '{print $2}')
      host=$(echo "${line}" | awk '{print $3}')

      if [[ -z ${id} ]] || [[ -z ${vcenter_id} ]]
      then
        continue
      fi

      # log_debug "        vspheredb: host: '${host}' / id: '${id}' / vcenter_id: '${vcenter_id}'"

      if [[ "${vcenter_id}" = "NULL" ]]
      then
        log_info "          - run initialize task for ${host}"
        /usr/bin/icingacli vspheredb task initialize --serverId ${id}
      else

        lockfile="/tmp/vspheredb_${host}_sync.lock"
        pid=$(ps aux | grep -v grep | grep "Icinga::vSphereDB::sync" | grep ${host} | awk '{print $1}')

        if [[ ! -e "${lockfile}" ]] && [[ -z ${pid} ]]
        then
          (
            log_info "          - run sync task for ${host}"
            touch ${lockfile}
            /usr/bin/icingacli vspheredb task sync --vCenterId ${vcenter_id}

            # log_debug "          - remove lockfile ${lockfile}"
            rm -f ${lockfile}
          ) &
        fi
      fi

    done< <(mysql \
          --defaults-file=${database_cnf} \
          --skip-column-names \
          --silent \
          --execute="select id, vcenter_id, host from vcenter_server order by id;")

    sleep 1m
  done
}


run() {

  log_info "        start the vspheredb monitor"

  create_secrets_file

  vspheredb_handler
}

run
