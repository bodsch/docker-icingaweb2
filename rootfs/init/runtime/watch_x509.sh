#!/bin/bash

# use inotify to detect changes in the ${monitored_directory} and sync
# changes to ${backup_directory}
# when a 'delete' event is triggerd, the file/directory will also removed
# from ${backup_directory}
#
#

. /init/output.sh

monitored_directory="/etc/icingaweb2/modules/x509"
hostname_f=$(hostname -f)

log_info "start the x509 monitor"


inotifywait \
  --monitor \
  --event close_write \
  --event close_nowrite \
  --event moved_to \
  --event move_self \
  --event attrib \
  ${monitored_directory} |
  while read path action file
  do
    [[ -z "${file}" ]] && continue
    [[ ${path} =~ backup ]] && continue

    # log_debug "x509 monitor - The file '$file' appeared in directory '$path' via '$action'"

    if [[ "${action}" = "ATTRIB" ]] && [[ "${file}" = "jobs.ini" ]]
    then

      for i in $(grep "\[" ${monitored_directory}/jobs.ini)
      do
        job=$(echo $i | sed -e 's|\[||' -e 's|\]||')
        log_info "      - scan x509 job ${job}"
        /usr/bin/icingacli x509 scan --job ${job}
      done
    fi

  done
