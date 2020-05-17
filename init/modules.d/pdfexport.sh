#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  pdfexport"

ICINGAWEB_PDF=${ICINGAWEB_PDF:-"false"}

check() {

  if [[ "${ICINGAWEB_PDF}" = "false" ]]
  then
    log_info "    pdfexport module support is disabled"

    disable_module pdfexport
    exit 0
  fi
}


configure() {

  local pdfexport="${ICINGAWEB_MODULES_DIRECTORY}/pdfexport"

  # icingaweb pdfexport
  #
  if [[ -d ${pdfexport} ]]
  then

    log_info "    configure pdfexport"

    enable_module pdfexport

  fi
}

check
configure
