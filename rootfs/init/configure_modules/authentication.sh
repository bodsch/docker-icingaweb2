
# configure the LDAP resources
#
ldap_configuation() {

  [[ "${USE_LDAP}" = "false" ]] && return

  backend="ldap"
  user_name_attribute="uid"
  user_class="inetOrgPerson"

  [[ "${LDAP_AD}" = "true" ]] && backend="msldap"
  [[ "${LDAP_AD}" = "true" ]] && user_name_attribute="sAMAccountName"
  [[ "${LDAP_AD}" = "true" ]] && user_class="user"


  # create a LDAP resource
  #
  if [[ $(grep -c "\[ldap\]" /etc/icingaweb2/resources.ini) -eq 0 ]]
  then
    log_info "  - LDAP resource"

    cat << EOF >> /etc/icingaweb2/resources.ini

[ldap]
type       = "ldap"
hostname   = "${LDAP_SERVER}"
port       = "${LDAP_PORT}"
encryption = "none"
root_dn    = "${LDAP_BASE_DN}"
bind_dn    = "${LDAP_BIND_DN}"
bind_pw    = "${LDAP_BIND_PASSWORD}"

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
user_class          = "${user_class}"
base_dn             = "${LDAP_BASE_DN}"
# the login AND displayed name
user_name_attribute = "${user_name_attribute}"

EOF
    if [[ ! -z "${LDAP_FILTER}" ]]
    then
      echo "filter              = \"${LDAP_FILTER}\"" >> /etc/icingaweb2/authentication.ini
    fi
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

    if [[ ! -z "${LDAP_ROLE_GROUPS}" ]]
    then
      cat << EOF >> /etc/icingaweb2/roles.ini

[ldap roles]
groups      = "${LDAP_ROLE_GROUPS}"
permissions = "${LDAP_ROLE_PERMISSIONS}"

EOF

    fi
  fi

}

# extract Environment variables
#
extract_vars() {

  # default values for our Environment
  #
  USE_LDAP=false
  LDAP_AD=${LDAP_AD:-false}
  LDAP_SERVER=${LDAP_SERVER:-}
  LDAP_PORT=${LDAP_PORT:-389}
  LDAP_USER_CLASS=${LDAP_USER_CLASS:-user}
  LDAP_BASE_DN=${LDAP_BASE_DN:-}
  LDAP_FILTER=${LDAP_FILTER:-}
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
      [[ "${LDAP_PORT}" == null ]] && LDAP_PORT=389
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
    LDAP_BIND_DN=${LDAP_BIND_DN:-}
    LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD:-}
    LDAP_ROLE_GROUPS=${LDAP_ROLE_GROUPS:-}
    LDAP_ROLE_PERMISSIONS=${LDAP_ROLE_PERMISSIONS:-'*'}
  fi

  validate_ldap_environment
}

# validate extracted Environment variables
#
validate_ldap_environment() {

  LDAP_AD=${LDAP_AD:-false}
  LDAP_SERVER=${LDAP_SERVER:-}
  LDAP_PORT=${LDAP_PORT:-389}
  LDAP_USER_CLASS=${LDAP_USER_CLASS:-user}
  LDAP_BASE_DN=${LDAP_BASE_DN:-}
  LDAP_FILTER=${LDAP_FILTER:-}
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

    export LDAP_AD
    export LDAP_FILTER
    export LDAP_SERVER
    export LDAP_PORT
    export LDAP_USER_CLASS
    export LDAP_BASE_DN
    export LDAP_FILTER
    export LDAP_BIND_DN
    export LDAP_ROLE_GROUPS
    export LDAP_ROLE_PERMISSIONS

    export USE_LDAP
  fi
}

extract_vars

ldap_configuation
