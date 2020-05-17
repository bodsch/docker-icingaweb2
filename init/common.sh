
enable_module() {

  local module="${1}"

  log_info "    enable module"
  [[ -d "/etc/icingaweb2/modules/${module}" ]] || mkdir -p "/etc/icingaweb2/modules/${module}"

  [[ -e "/etc/icingaweb2/enabledModules/${module}" ]] || ln -s "${ICINGAWEB_MODULES_DIRECTORY}/${module}" /etc/icingaweb2/enabledModules/
}


disable_module() {

  local module="${1}"

  [[ -e "/etc/icingaweb2/modules/${module}" ]]        && rm -rf "/etc/icingaweb2/modules/${module}"
  [[ -e "/etc/icingaweb2/enabledModules/${module}" ]] && rm -rf "/etc/icingaweb2/enabledModules/${module}"
}

list_module() {

  local module="${1}"

  if [[ -e "${ICINGAWEB_MODULES_DIRECTORY}/${module}" ]]
  then
    echo 1
  else
    echo 0
  fi
}

