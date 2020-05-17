#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  toplevelview module"

ICINGAWEB_TLV=${ICINGAWEB_TLV:-"true"}

check() {

  if [[ "${ICINGAWEB_TLV}" = "false" ]]
  then
    log_info "    toplevelview module support is disabled"

    disable_module toplevelview
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/toplevelview"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/toplevelview ]] || mkdir -p /etc/icingaweb2/modules/toplevelview

    log_info "    enabling toplevelview module"

    enable_module toplevelview
  fi
}

check
configure
