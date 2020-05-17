#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  aws module"

ICINGAWEB_AWS=${ICINGAWEB_AWS:-"true"}

check() {

  if [[ "${ICINGAWEB_AWS}" = "false" ]]
  then
    log_info "    aws module support is disabled"

    disable_module aws
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/aws"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/aws ]] || mkdir -p /etc/icingaweb2/modules/aws

    log_info "    enabling aws module"

    enable_module aws
  fi
}

check
configure
