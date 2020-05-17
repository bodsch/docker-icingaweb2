#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  cube module"

ICINGAWEB_CUBE=${ICINGAWEB_CUBE:-"true"}

check() {

  if [[ "${ICINGAWEB_CUBE}" = "false" ]]
  then
    log_info "    cube module support is disabled"

    disable_module cube
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/cube"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/cube ]] || mkdir -p /etc/icingaweb2/modules/cube

    log_info "    enabling cube module"

    enable_module cube
  fi
}

check
configure
