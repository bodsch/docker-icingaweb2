
# enable Icingaweb2 Feature
#
enable_icinga_feature() {

  local feature="${1}"

  if [[ $(/usr/bin/icingacli module feature list | grep Enabled | grep -c ${feature}) -eq 0 ]]
  then
    log_info "feature ${feature} enabled"
    icinga2 feature enable ${feature} > /dev/null
  fi
}

# disable Icingaweb2 Feature
#
disable_icinga_feature() {

  local feature="${1}"

  if [[ $(icinga2 feature list | grep Enabled | grep -c ${feature}) -eq 1 ]]
  then
    log_info "feature ${feature} disabled"
    icinga2 feature disable ${feature} > /dev/null
  fi
}

