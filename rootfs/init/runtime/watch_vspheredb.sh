#!/bin/bash

# use inotify to detect changes in the ${monitored_directory} and sync
# changes to ${backup_directory}
# when a 'delete' event is triggerd, the file/directory will also removed
# from ${backup_directory}
#
#

. /init/output.sh
. /init/ini_parser.sh

monitored_directory="/etc/icingaweb2/modules/vspheredb"
hostname_f=$(hostname -f)

database_cnf="${monitored_directory}/.my.cnf"

log_info "start the vspheredb monitor"

if [[ ! -f "${database_cnf}" ]]
then

    log_info "read database resource ..."
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
    id=$(echo $line | awk '{print $1}')
    vcenter_id=$(echo $line | awk '{print $1=""; print $0}'|sed ':a;N;$!ba;s/\n/ /g'| sed 's/^[ \t]*//g')
    host=$(echo $line | awk '{print $1=""; print $0}'|sed ':a;N;$!ba;s/\n/ /g'| sed 's/^[ \t]*//g')
#    echo "ID: $id"
#    echo "VALUE: $vcenter_id"
  done< <(mysql \
        --defaults-file=${database_cnf} \
        --skip-column-names \
        --silent \
        --execute="select id, vcenter_id, host from vcenter_server;")

  log_debug "vspheredb: host: '${host} / id: '${id}' / vcenter_id:'${vcenter_id}'"

  if [[ "${vcenter_id}" = "NULL" ]]
  then
    log_debug " vcenter_id == NULL - run initialize task"
    /usr/bin/icingacli vspheredb task initialize --serverId ${id}

    sleep 5s

    /usr/bin/icingacli vspheredb task sync --vCenterId ${id} &
  fi

  sleep 1m
done

