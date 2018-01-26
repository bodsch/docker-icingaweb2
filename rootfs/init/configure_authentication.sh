

ldap_configuation() {

set -x

  [[ "${USE_LDAP}" == "false" ]] && return


  return
set +x

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
  user_name_attribute="uid"

  [[ "${active_directory}" == "true" ]] && backend="msldap"
  [[ "${active_directory}" == "true" ]] && user_name_attribute="sAMAccountName"

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
user_name_attribute = "${user_name_attribute}"
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


extract_vars() {

  # default values for our Environment
  #
  LDAP_AD=${LDAP_AD:-false}
  LDAP_SERVER=${LDAP_SERVER:-}
  LDAP_PORT=${LDAP_PORT:-389}
  LDAP_USER_CLASS=${LDAP_USER_CLASS:-user}
  LDAP_BASE_DN=${LDAP_BASE_DN:-}
  LDAP_FILTER=${LDAP_FILTER:-}
  LDAP_ROOT_DN=${LDAP_ROOT_DN:-}
  LDAP_BIND_DN=${LDAP_BIND_DN:-}
  LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD:-}
  LDAP_ROLE_GROUPS=${LDAP_ROLE_GROUPS:-}
  LDAP_ROLE_PERMISSIONS=${LDAP_ROLE_PERMISSIONS:-'*'}

  USE_JSON="true"

  # detect if 'LDAP' an json
  #
  if ( [[ ! -z "${LDAP}" ]] && [[ "${LDAP}" != "true" ]] && [[ "${LDAP}" != "false" ]] )
  then
    echo "${LDAP}" | json_verify -q 2> /dev/null

    if [[ $? -gt 0 ]]
    then
      log_info "the LDAP Environment is not an json"
#       log_info "use fallback strategy."
      USE_JSON="false"
    fi
  else
    log_info "the LDAP Environment is not an json"
#     log_info "use fallback strategy."
    USE_JSON="false"
  fi

  # we can use json as configure
  #
  if [[ "${USE_JSON}" == "true" ]]
  then

    log_info "the LDAP Environment is an json"

    if ( [[ "${LDAP}" == "true" ]] || [[ "${LDAP}" == "false" ]] )
    then
      log_error "the LDAP Environment must be an json, not true or false!"
    else

      LDAP_AD=$(echo "${LDAP}" | jq --raw-output .active_directory)
      LDAP_SERVER=$(echo "${LDAP}" | jq --raw-output .server)
      LDAP_PORT=$(echo "${LDAP}" | jq --raw-output .port)
      LDAP_BIND_DN=$(echo "${LDAP}" | jq --raw-output .bind_dn)
      LDAP_BIND_PASSWORD=$(echo "${LDAP}" | jq --raw-output .bind_password)
      LDAP_BASE_DN=$(echo "${LDAP}" | jq --raw-output .base_dn)
      LDAP_FILTER=$(echo "${LDAP}" | jq --raw-output .filter)
      LDAP_ROLE_GROUPS=$(echo "${LDAP}" | jq --raw-output .role.groups)
      LDAP_ROLE_PERMISSIONS=$(echo "${LDAP}" | jq --raw-output .role.permissions)

      [[ "${LDAP_AD}" == null ]] && LDAP_AD=
      [[ "${LDAP_SERVER}" == null ]] && LDAP_SERVER=
      [[ "${LDAP_PORT}" == null ]] && LDAP_PORT=8080
      [[ "${LDAP_BIND_DN}" == null ]] && LDAP_BIND_DN=
      [[ "${LDAP_BIND_PASSWORD}" == null ]] && LDAP_BIND_PASSWORD=
      [[ "${LDAP_BASE_DN}" == null ]] && LDAP_BASE_DN=
      [[ "${LDAP_FILTER}" == null ]] && LDAP_FILTER=
      [[ "${LDAP_ROLE_GROUPS}" == null ]] && LDAP_ROLE_GROUPS=
      [[ "${LDAP_ROLE_PERMISSIONS}" == null ]] && LDAP_ROLE_PERMISSIONS='*'
    fi
  else
    LDAP_AD=${LDAP_AD:-false}
    LDAP_SERVER=${LDAP_SERVER:-}
    LDAP_PORT=${LDAP_PORT:-389}
    LDAP_USER_CLASS=${LDAP_USER_CLASS:-user}
    LDAP_BASE_DN=${LDAP_BASE_DN:-}
    LDAP_FILTER=${LDAP_FILTER:-}
    LDAP_ROOT_DN=${LDAP_ROOT_DN:-}
    LDAP_BIND_DN=${LDAP_BIND_DN:-}
    LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD:-}
    LDAP_ROLE_GROUPS=${LDAP_ROLE_GROUPS:-}
    LDAP_ROLE_PERMISSIONS=${LDAP_ROLE_PERMISSIONS:-'*'}
  fi

  validate_ldap_environment
}

validate_ldap_environment() {

  LDAP_AD=${LDAP_AD:-false}
  LDAP_SERVER=${LDAP_SERVER:-}
  LDAP_PORT=${LDAP_PORT:-389}
  LDAP_USER_CLASS=${LDAP_USER_CLASS:-user}
  LDAP_BASE_DN=${LDAP_BASE_DN:-}
  LDAP_FILTER=${LDAP_FILTER:-}
  LDAP_ROOT_DN=${LDAP_ROOT_DN:-}
  LDAP_BIND_DN=${LDAP_BIND_DN:-}
  LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD:-}
  LDAP_ROLE_GROUPS=${LDAP_ROLE_GROUPS:-}
  LDAP_ROLE_PERMISSIONS=${LDAP_ROLE_PERMISSIONS:-'*'}

  # use the new Cert Service to create and get a valide certificat for distributed icinga services
  #
  if (

    [[ ! -z ${LDAP_AD} ]] &&
    [[ ! -z ${LDAP_SERVER} ]] &&
    [[ ! -z ${LDAP_PORT} ]] &&
    [[ ! -z ${LDAP_BIND_DN} ]] &&
    [[ ! -z ${LDAP_BIND_PASSWORD} ]] &&
    [[ ! -z ${LDAP_BASE_DN} ]] &&
    [[ ! -z ${LDAP_FILTER} ]] &&
    [[ ! -z ${LDAP_ROLE_GROUPS} ]] &&
    [[ ! -z ${LDAP_ROLE_PERMISSIONS} ]]
  )
  then
    USE_LDAP=true

    export LDAP_FILTER
    export LDAP_SERVER
    export LDAP_PORT
    export LDAP_USER_CLASS
    export LDAP_BASE_DN
    export LDAP_FILTER
    export LDAP_ROOT_DN
    export LDAP_BIND_DN
    export LDAP_ROLE_GROUPS
    export LDAP_ROLE_PERMISSIONS
  fi
}

extract_vars

ldap_configuation

