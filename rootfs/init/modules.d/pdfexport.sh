#!/bin/bash
#
#

. /init/output.sh
. /init/common.sh

log_info "  pdfexport"

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

configure

# EOF
