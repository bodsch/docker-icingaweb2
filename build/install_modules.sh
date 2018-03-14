#!/bin/bash
#
# install a set of icingaweb2 modules

[[ "${INSTALL_MODULES}" = "false" ]] && exit 0

MODULE_DIRECTORY="/usr/share/webapps/icingaweb2/modules"
MODULE_LIST="\
    Icinga|director|1.4.3 \
    Icinga|vsphere|1.0.0 \
    Icinga|graphite|0.9.0 \
    Icinga|generictts|2.0.0 \
    Icinga|businessprocess|2.1.0 \
    Icinga|elasticsearch|0.9.0 \
    Icinga|cube|1.0.1 \
    Mikesch-mp|grafana|1.2.0"

cd ${MODULE_DIRECTORY}

for g in ${MODULE_LIST} ; do \
  maintainer="$(echo "${g}" | cut -d "|" -f1)"
  module="$(echo "${g}" | cut -d "|" -f2)"
  version="$(echo "${g}" | cut -d "|" -f3)"

  echo "install module '$module' v$version"

  curl \
    --silent \
    --location \
    --retry 3 \
    --output "${module}.tgz" \
  https://github.com/${maintainer}/icingaweb2-module-${module}/archive/v${version}.tar.gz

  tar -xzf ${module}.tgz
  mv icingaweb2-module-${module}-${version} ${module}
  rm -f ${module}.tgz
  mkdir /etc/icingaweb2/modules/${module}
  /usr/bin/icingacli module enable ${module}
done
