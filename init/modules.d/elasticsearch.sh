#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  elasticsearch module"

ICINGAWEB_ES=${ICINGAWEB_ES:-"false"}

check() {

  if [[ "${ICINGAWEB_ES}" = "false" ]]
  then
    log_info "    elasticsearch module support is disabled"

    disable_module elasticsearch
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/elasticsearch"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/elasticsearch ]] || mkdir -p /etc/icingaweb2/modules/elasticsearch

    log_info "    enabling elasticsearch module"

    enable_module elasticsearch
  fi
}

check
configure
