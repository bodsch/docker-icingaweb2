
# wait for grafana
#
wait_for_grafana() {

  . /init/wait_for/dns.sh
  . /init/wait_for/port.sh

  wait_for_dns ${GRAFANA_HOST}
  wait_for_port ${GRAFANA_HOST} ${GRAFANA_PORT} 15

  sleep 2s
}

wait_for_grafana
