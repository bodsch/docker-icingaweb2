#!/bin/bash
#
#

. /init/output.sh

log_info "  command transport"

ICINGA2_MASTER=${ICINGA2_MASTER:-"icinga2-master"}
ICINGA2_MASTER2=${ICINGA2_MASTER2:-""}
ICINGA2_PORT=${ICINGA2_PORT:-5665}

ICINGA2_CMD_API_USER=${ICINGA2_CMD_API_USER:-""}
ICINGA2_CMD_API_PASS=${ICINGA2_CMD_API_PASS:-""}

# -------------------------------------------------------------------------------------------------

check() {
  if ( [[ -z ${ICINGA2_MASTER} ]] || [[ -z ${ICINGA2_CMD_API_USER} ]] || [[ -z ${ICINGA2_CMD_API_PASS} ]] )
  then
    log_warn "   no valid information for command transport over API"
    exit 0
  fi
}

configure() {

  log_info "    configure command transport over API"

  if ( [[ -z ${ICINGA2_MASTER2} ]] )
  then
    log_info "   single api commandtransports setup!"
  cat << EOF > /etc/icingaweb2/modules/monitoring/commandtransports.ini
[icinga]
transport = "api"
host      = "${ICINGA2_MASTER}"
port      = "${ICINGA2_PORT}"
username  = "${ICINGA2_CMD_API_USER}"
password  = "${ICINGA2_CMD_API_PASS}"
instance  = "${ICINGA2_MASTER}
EOF
  fi
    log_info "   multi master api commandtransports setup!"

  cat << EOF > /etc/icingaweb2/modules/monitoring/commandtransports.ini

[icinga1]
transport = "api"
host      = "${ICINGA2_MASTER}"
port      = "${ICINGA2_PORT}"
username  = "${ICINGA2_CMD_API_USER}"
password  = "${ICINGA2_CMD_API_PASS}"
instance  = "${ICINGA2_MASTER}"

[icinga2]
transport = "api"
host      = "${ICINGA2_MASTER2}"
port      = "${ICINGA2_PORT}"
username  = "${ICINGA2_CMD_API_USER}"
password  = "${ICINGA2_CMD_API_PASS}"
instance  = "${ICINGA2_MASTER2}"

EOF

}

check
configure

# EOF
