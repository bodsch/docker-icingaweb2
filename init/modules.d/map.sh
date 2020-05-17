#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  map module"

ICINGAWEB_MAP=${ICINGAWEB_MAP:-"true"}

check() {

  if [[ "${ICINGAWEB_MAP}" = "false" ]]
  then
    log_info "    map module support is disabled"

    disable_module map
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/map"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/map ]] || mkdir -p /etc/icingaweb2/modules/map

    log_info "    enabling map module"

    enable_module map
  fi
}

check
configure
