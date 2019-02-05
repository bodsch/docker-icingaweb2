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

log_info "        start the vspheredb monitor"

if [[ ! -f "${database_cnf}" ]]
then

    log_info "        read database resource ..."
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

while true
do
  while read -r line; do
    id=$(echo "${line}" | awk '{print $1}')
    vcenter_id=$(echo "${line}" | awk '{print $2}')
    host=$(echo "${line}" | awk '{print $3}')

    if [[ -z ${id} ]] || [[ -z ${vcenter_id} ]]
    then
      log_debug "no vcenter configured"
      pids=$(ps aux | grep -v grep | grep "Icinga::vSphereDB::sync" | awk '{print $1}' | wc -l)

      if [[ ${pids} -gt 0 ]]
      then
        log_debug "found ${pids} vSphereDB::sync tasks"
        for p in ${pids}
        do
          kill -15 ${p}
        done
      fi

      continue
    fi

    # log_debug "        vspheredb: host: '${host}' / id: '${id}' / vcenter_id: '${vcenter_id}'"

    if [[ "${vcenter_id}" = "NULL" ]]
    then
      log_info "          - run initialize task for ${host}"
      /usr/bin/icingacli vspheredb task initialize --serverId ${id}
    else

      lockfile="/tmp/vspheredb_vcenter_id_${vcenter_id}.lock"
      pid=$(ps aux | grep -v grep | grep "Icinga::vSphereDB::sync" | grep ${host} | awk '{print $1}')

      if [[ ! -e "${lockfile}" ]]&& [[ -z ${pid} ]]
      then
        (
          log_info "          - run sync task for ${host}"
          touch ${lockfile}
          /usr/bin/icingacli vspheredb task sync --vCenterId ${vcenter_id}
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
