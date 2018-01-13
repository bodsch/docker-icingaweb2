

ICINGA2_HOST=${ICINGA2_HOST:-"icinga2-master"}
ICINGA2_PORT=${ICINGA2_PORT:-5665}

ICINGA2_CMD_API_USER=${ICINGA2_CMD_API_USER:-""}
ICINGA2_CMD_API_PASS=${ICINGA2_CMD_API_PASS:-""}

# -------------------------------------------------------------------------------------------------

if ( [[ -z ${ICINGA2_HOST} ]] || [[ -z ${ICINGA2_CMD_API_USER} ]] || [[ -z ${ICINGA2_CMD_API_PASS} ]] )
then
  return
fi

configure_command_transport() {

  log_info "configure command transport over API"

  cat << EOF > /etc/icingaweb2/modules/monitoring/commandtransports.ini

[icinga]
transport = "api"
host      = "${ICINGA2_HOST}"
port      = "${ICINGA2_PORT}"
username  = "${ICINGA2_CMD_API_USER}"
password  = "${ICINGA2_CMD_API_PASS}"

EOF

}

configure_command_transport

# EOF
