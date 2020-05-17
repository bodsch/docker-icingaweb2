#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  particles module"

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/particles"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/particles ]] || mkdir -p /etc/icingaweb2/modules/particles

    log_info "    enabling particles module"

    enable_module particles
  fi
}

configure
