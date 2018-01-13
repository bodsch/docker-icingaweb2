

ldap_configuation() {

  local active_directory=${1}
  local server=${2}
  local port=${3}
  local bind_dn=${4}
  local bind_password=${5}
  local base_dn=${6}
  local search_filter=${7}
  local role_group_names=${8}
  local role_permissions=${9}

  if ( [[ -z ${server} ]] || [[ ${server} == null ]] )
  then
    return
  fi

  log_info "create LDAP configuration"

  [[ ${#port} -eq 0 ]] && port=389
  [[ ${#search_filter} -eq 0 ]] && search_filter="uid"

  backend="ldap"

  [[ "${active_directory}" == "true" ]] && backend="msldap"

  # create a LDAP resource
  #
  if [[ $(grep -c "\[ldap\]" /etc/icingaweb2/resources.ini) -eq 0 ]]
  then
    log_info "  - LDAP resource"

    cat << EOF >> /etc/icingaweb2/resources.ini

[ldap]
type       = "ldap"
hostname   = "${server}"
port       = "${port}"
encryption = "none"
root_dn    = "${base_dn}"
bind_dn    = "${bind_dn}"
bind_pw    = "${bind_password}"

EOF
  fi

  # add user authentication
  #
  if [[ $(grep -c "\[ldap users\]" /etc/icingaweb2/authentication.ini) -eq 0 ]]
  then
    log_info "  - LDAP authentication"

    cat << EOF >> /etc/icingaweb2/authentication.ini

[ldap users]
backend             = "${backend}"
resource            = "ldap"
user_class          = "user"
base_dn             = "${base_dn}"
# the login AND displayed name
user_name_attribute = "name"
filter              = "${filter}"

EOF
  fi

  # add group filter
  #
  if ( [[ ! -f /etc/icingaweb2/groups.ini ]] || [[ $(grep -c "\[ldap groups\]" /etc/icingaweb2/groups.ini) -eq 0 ]] )
  then
    log_info "  - LDAP groups"

    cat << EOF >> /etc/icingaweb2/groups.ini

[ldap groups]
backend      = "${backend}"
resource     = "ldap"
user_backend = "ldap users"
# the displayed name
group_name_attribute = "cn"

EOF
  fi


  # add LDAP role
  #
  if [[ $(grep -c "\[ldap roles\]" /etc/icingaweb2/roles.ini) -eq 0 ]]
  then
    log_info "  - LDAP roles"

    if [[ ! -z ${role_group_names} ]]
    then
      cat << EOF >> /etc/icingaweb2/roles.ini

[ldap roles]
groups      = "${role_group_names}"
permissions = "${role_permissions}"

EOF

    fi
  fi
}

ldap_authentication() {

  ldap=$(echo "${LDAP}"  | jq '.')

  if [[ ! -z "${ldap}" ]]
  then
    echo "${ldap}" | jq --compact-output --raw-output '.' | while IFS='' read u
    do
      active_directory=$(echo "${u}" | jq --raw-output .active_directory)
      server=$(echo "${u}" | jq --raw-output .server)
      port=$(echo "${u}" | jq --raw-output .port)
      bind_dn=$(echo "${u}" | jq --raw-output .bind_dn)
      bind_password=$(echo "${u}" | jq --raw-output .bind_password)
      base_dn=$(echo "${u}" | jq --raw-output .base_dn)
      filter=$(echo "${u}" | jq --raw-output .filter)
      role_group_names=$(echo "${u}" | jq --raw-output .role.groups)
      role_permissions=$(echo "${u}" | jq --raw-output .role.permissions)

      [[ ${active_directory} = null ]] && active_directory="false"
      [[ ${role_group_names} = null ]] && role_group_names=
      [[ ${role_permissions} = null ]] && role_permissions='*'

      ldap_configuation "${active_directory}" "${server}" "${port}" "${bind_dn}" "${bind_password}" "${base_dn}" "${filter}" "${role_group_names}" "${role_permissions}"
    done
  fi
}


ldap_authentication

