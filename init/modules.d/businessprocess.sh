#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  businessprocess module"

ICINGAWEB_BP=${ICINGAWEB_BP:-"true"}

check() {

  if [[ "${ICINGAWEB_BP}" = "false" ]]
  then
    log_info "    businessprocess module support is disabled"

    disable_module businessprocess
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/businessprocess"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/businessprocess ]] || mkdir -p /etc/icingaweb2/modules/businessprocess

    log_info "    enabling businessprocess module"

    enable_module businessprocess
  fi
}

check
configure
