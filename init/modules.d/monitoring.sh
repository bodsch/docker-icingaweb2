#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  monitoring"

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/monitoring"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/monitoring ]] || mkdir -p /etc/icingaweb2/modules/monitoring

    log_info "    enabling monitoring module"

    enable_module monitoring
  fi
}

configure
