
# LIVESTATUS_HOST
# LIVESTATUS_PORT

if ( [[ -z ${LIVESTATUS_HOST} ]] && [[ -z ${LIVESTATUS_PORT} ]] )
then
  return
fi

configure_icinga_livestatus() {

  log_info " enable Live status for Host '${LIVESTATUS_HOST}'"

  if [[ $(grep -c "livestatus-tcp]" /etc/icingaweb2/resources.ini) -eq 0 ]]
  then
    cat << EOF >> /etc/icingaweb2/resources.ini

[livestatus-tcp]
type                = "livestatus"
socket              = "tcp://${LIVESTATUS_HOST}:${LIVESTATUS_PORT}"

EOF
  fi
}

configure_icinga_livestatus

# EOF
