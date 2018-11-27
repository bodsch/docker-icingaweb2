#!/bin/bash
#
#

CERTS_FILE=${CERTS_FILE:-"/etc/ssl/certs/ca-certificates.crt"}

. /init/output.sh

log_info "  - x509"

check() {
  log_info "check"
}

configure() {
  log_info "check"

  if [[ -f ${CERTS_FILE} ]]
  then
    icingacli x509 import --file ${CERTS_FILE}
  fi

}

create_database() {
  log_info "create_database"
}
