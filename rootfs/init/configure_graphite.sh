
configure_icinga_graphite() {

  echo " [i] graphite support is currently disabled"

  return

  if [ ! -d /etc/icingaweb2/modules/graphite/templates ]
  then
    cp -arv /usr/share/webapps/icingaweb2/modules/graphite/sample-config/icinga2/* /etc/icingaweb2/modules/graphite/
  fi

  if [ -f /etc/icingaweb2/modules/graphite/config.ini ]
  then
    # TODO
    # fix it
    sed -i \
      -e "s|my.graphite.web|${GRAPHITE_HOST}:${GRAPHITE_PORT}|g" \
      /etc/icingaweb2/modules/graphite/config.ini
  fi
}

configure_icinga_graphite

# EOF
