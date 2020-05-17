#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  globe module"

ICINGAWEB_GLOBE=${ICINGAWEB_GLOBE:-"true"}

check() {

  if [[ "${ICINGAWEB_GLOBE}" = "false" ]]
  then
    log_info "    globe module support is disabled"

    disable_module globe
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/globe"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/globe ]] || mkdir -p /etc/icingaweb2/modules/globe

    log_info "    enabling globe module"

    enable_module globe
  fi
}

check
configure
