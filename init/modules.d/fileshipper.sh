#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  fileshipper module"

ICINGAWEB_FILESHIPPER=${ICINGAWEB_FILESHIPPER:-"false"}

check() {

  if [[ "${ICINGAWEB_FILESHIPPER}" = "false" ]]
  then
    log_info "    fileshipper module support is disabled"

    disable_module fileshipper
    exit 0
  fi
}

configure() {

  local module_directory="${ICINGAWEB_MODULES_DIRECTORY}/fileshipper"

  # icingaweb module_directory
  #
  if [[ -d ${module_directory} ]]
  then

    [[ -d /etc/icingaweb2/modules/fileshipper ]] || mkdir -p /etc/icingaweb2/modules/fileshipper

    log_info "    enabling fileshipper module"

    enable_module fileshipper
  fi
}

check
configure
