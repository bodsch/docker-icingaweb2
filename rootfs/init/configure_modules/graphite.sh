
if ( [[ -z ${GRAPHITE_HOST} ]] || [[ -z ${GRAPHITE_HTTP_PORT} ]] )
then
  log_info "disable graphite support while missing GRAPHITE_HOST or GRAPHITE_HTTP_PORT"

  /usr/bin/icingacli module disable graphite
  return
fi

configure_icinga_graphite() {

  log_info "configure graphite support"

  if [[ $(/usr/bin/icingacli module list | grep -c graphite) -eq 0 ]]
  then
    log_warn "Module graphite is not installed"
    return
  fi

  /usr/bin/icingacli module enable graphite

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
}

configure_icinga_graphite

# EOF
