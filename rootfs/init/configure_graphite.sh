
if ( [[ -z ${GRAPHITE_HOST} ]] || [[ -z ${GRAPHITE_HTTP_PORT} ]] )
then

  log_info "missing GRAPHITE_HOST or GRAPHITE_HTTP_PORT"
  log_info "disable graphite support"

  /usr/bin/icingacli module disable graphite
  return
fi

configure_icinga_graphite() {

  log_info "configure graphite support"

  cat << EOF >> /etc/icingaweb2/modules/graphite/config.ini

[graphite]
url = "http://${GRAPHITE_HOST}:${GRAPHITE_HTTP_PORT}"
; user = "user"
; password = "pass"

;[icinga]
; graphite_writer_host_name_template = "host tpl"
; graphite_writer_service_name_template = "service tpl"

EOF
}

configure_icinga_graphite

# EOF
