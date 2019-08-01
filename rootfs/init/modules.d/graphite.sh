#!/bin/bash
#
#

GRAPHITE_HOST=${GRAPHITE_HOST:-""}
GRAPHITE_HTTP_PORT=${GRAPHITE_HTTP_PORT:-8080}

. /init/output.sh
. /init/common.sh

log_info "  graphite"

check() {

  if ( [[ -z ${GRAPHITE_HOST} ]] || [[ -z ${GRAPHITE_HTTP_PORT} ]] )
  then
    log_info "    disable graphite support while missing GRAPHITE_HOST or GRAPHITE_HTTP_PORT"

    disable_module graphite
    exit 0
  fi

}

configure() {

  if [[ $(list_module graphite) -eq 0 ]]
  then
    log_warn "graphite module is not installed"
    exit 0
  fi

  log_info "    create config files for icingaweb"

  [[ -d /etc/icingaweb2/modules/graphite ]] || mkdir -p /etc/icingaweb2/modules/graphite

  cat << EOF > /etc/icingaweb2/modules/graphite/config.ini

[graphite]
url = "http://${GRAPHITE_HOST}:${GRAPHITE_HTTP_PORT}"
; user = "user"
; password = "pass"

[ui]
default_time_range = "12"
default_time_range_unit = "hours"
disable_no_graphs_found = "0"

;[icinga]
; graphite_writer_host_name_template = "host tpl"
; graphite_writer_service_name_template = "service tpl"

EOF

  enable_module graphite
}

check
configure

# EOF
