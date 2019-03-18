#!/bin/bash
#

GRAFANA_HOST=${GRAFANA_HOST:-grafana}
GRAFANA_PORT=${GRAFANA_PORT:-3000}

GRAFANA_TIMERANGE=${GRAFANA_TIMERANGE:-12h}
GRAFANA_TIMERANGE_ALL=${GRAFANA_TIMERANGE_ALL:-7d}

GRAFANA_DASHBOARD=${GRAFANA_DASHBOARD:-icinga2-default}
GRAFANA_DASHBOARD_UID=${GRAFANA_DASHBOARD_UID:-}
GRAFANA_PROTOCOL=${GRAFANA_PROTOCOL:-http}
GRAFANA_ACCESS=${GRAFANA_ACCESS:-proxy}

GRAFANA_AUTHENTICATION=${GRAFANA_AUTHENTICATION:-token}
GRAFANA_AUTHENTICATION_TOKEN=${GRAFANA_AUTHENTICATION_TOKEN:-}
GRAFANA_AUTHENTICATION_USERNAME=${GRAFANA_AUTHENTICATION_USERNAME:-admin}
GRAFANA_AUTHENTICATION_PASSWORD=${GRAFANA_AUTHENTICATION_PASSWORD:-admin}

GRAFANA_DATASOURCE=${GRAFANA_DATASOURCE:-influxdb}

GRAFANA_ENABLE_LINK=${GRAFANA_ENABLE_LINK:-no}
GRAFANA_SHOW_DEBUG=${GRAFANA_SHOW_DEBUG:-0}
GRAFANA_PUBLIC=${GRAFANA_PUBLIC:-no}
GRAFANA_PUBLIC_HOST=${GRAFANA_PUBLIC_HOST:-localhost/grafana/}
GRAFANA_PUBLIC_PROTOCOL=${GRAFANA_PUBLIC_PROTOCOL:-http}
GRAFANA_THEME=${GRAFANA_THEME:-light}

GRAFANA_PROXY_TIMEOUT=${GRAFANA_PROXY_TIMEOUT:-5}

. /init/output.sh

log_info "  - grafana"

check() {

  if ( [[ -z ${GRAFANA_HOST} ]] || [[ -z ${GRAFANA_PORT} ]] )
  then
    log_info "    disable grafana support while missing GRAFANA_HOST or GRAFANA_PORT"

    /usr/bin/icingacli module disable grafana
    exit 0
  fi
}


create_token() {

  log_info "     create API token"

  API_TOKEN_FILE="/tmp/grafana.test"
  api_key="icingaweb2"

  curl_opts="--silent --insecure --user ${GRAFANA_AUTHENTICATION_USERNAME}:${GRAFANA_AUTHENTICATION_PASSWORD}"

  data=$(curl \
    ${curl_opts} \
    --header "Content-Type: application/json" \
    http://${GRAFANA_HOST}:${GRAFANA_PORT}/api/auth/keys)

  result=${?}

  existing_api_key=$(echo "${data}" | jq --raw-output .[].name)

  if [[ -n ${existing_api_key} ]] && [[ -f ${API_TOKEN_FILE} ]]
  then
    log_debug "       reuse token"

    GRAFANA_AUTHENTICATION_TOKEN=$(jq --raw-output .key ${API_TOKEN_FILE})
    API_NAME=$(jq --raw-output .name ${API_TOKEN_FILE})
  else

    code=$(curl \
      ${curl_opts} \
      --request POST \
      --header "Content-Type: application/json" \
      --write-out '%{http_code}\n' \
      --output ${API_TOKEN_FILE} \
      --data "{\"name\":\"${api_key}\", \"role\": \"Admin\"}" \
      http://${GRAFANA_HOST}:${GRAFANA_PORT}/api/auth/keys)

    result=${?}

    if [[ ${result} -eq 0 ]] && [[ ${code} = 200 ]]
    then
      log_debug "     token request are successfull"

      GRAFANA_AUTHENTICATION_TOKEN=$(jq --raw-output .key ${API_TOKEN_FILE})

      export GRAFANA_AUTHENTICATION_TOKEN
    else
      echo ${code}
      log_error "     token request failed"
      #exit 1
    fi
  fi
}


configure() {

  if [[ $(/usr/bin/icingacli module list | grep -c grafana) -eq 0 ]]
  then
    log_warn "    grafana module is not installed"
    exit 0
  fi

  log_info "     create config files for icingaweb"

  [[ -d /etc/icingaweb2/modules/grafana ]] || mkdir -p /etc/icingaweb2/modules/grafana

  cat << EOF > /etc/icingaweb2/modules/grafana/config.ini

[grafana]
version                 = 1
host                    = "${GRAFANA_HOST}:${GRAFANA_PORT}"
protocol                = "${GRAFANA_PROTOCOL}"
timerangeAll            = "${GRAFANA_TIMERANGE_ALL}"
timerange               = "${GRAFANA_TIMERANGE}"
# timerangeAll            = "1w/w"
defaultdashboard        = "${GRAFANA_DASHBOARD}"
defaultdashboarduid     = "${GRAFANA_DASHBOARD_UID}"
defaultdashboardpanelid = 1
defaultorgid            = 1
shadows                 = 0
theme                   = "${GRAFANA_THEME}"
datasource              = "${GRAFANA_DATASOURCE}"
accessmode              = "${GRAFANA_ACCESS}"
height                  = 280
width                   = 640
enableLink              = ${GRAFANA_ENABLE_LINK}
debug                   = ${GRAFANA_SHOW_DEBUG}
usepublic               = ${GRAFANA_PUBLIC}
publichost              = ${GRAFANA_PUBLIC_HOST}
publicprotocol          = ${GRAFANA_PUBLIC_PROTOCOL}
proxytimeout            = ${GRAFANA_PROXY_TIMEOUT}
EOF

  if [[ "${GRAFANA_AUTHENTICATION}" = "token" ]] && [[ -z "${GRAFANA_AUTHENTICATION_TOKEN}" ]]
  then
    . /init/wait_for/grafana.sh

    create_token

    if [[ -z "${GRAFANA_AUTHENTICATION_TOKEN}" ]]
    then
      log_error "token creation failed"
      log_error "use fallback"

      GRAFANA_AUTHENTICATION="basic"
    fi
  fi


  # authentications ...
  if [[ "${GRAFANA_AUTHENTICATION}" = "token" ]]
  then

    cat << EOF >> /etc/icingaweb2/modules/grafana/config.ini

authentication          = "token"
apitoken                = "${GRAFANA_AUTHENTICATION_TOKEN}"

EOF

  elif [[ "${GRAFANA_AUTHENTICATION}" = "basic" ]]
  then
    cat << EOF >> /etc/icingaweb2/modules/grafana/config.ini

authentication          = "basic"
username                = "${GRAFANA_AUTHENTICATION_USERNAME}"
password                = "${GRAFANA_AUTHENTICATION_PASSWORD}"

EOF
  elif [[ "${GRAFANA_AUTHENTICATION}" = "anon" ]]
  then
    cat << EOF >> /etc/icingaweb2/modules/grafana/config.ini

# anonymous
authentication          = "anon"

EOF
  else

    log_warn "wrong authentication configured"
    log_warn "use 'anonymous' as default"

    cat << EOF >> /etc/icingaweb2/modules/grafana/config.ini

# anonymous
authentication = "anon"

EOF

  fi

  log_info "     enable module"
  /usr/bin/icingacli module enable grafana

}

check
configure

# EOF

# [grafana]
# version = "1"
# host = "grafana:3000"
# protocol = "http"
# timerangeAll = "1w/w"
# defaultdashboard = "icinga2-default"
# defaultdashboarduid = "icinga2-default"
# defaultdashboardpanelid = "1"
# defaultorgid = "1"
# shadows = "0"
# theme = "light"
# datasource = "influxdb"
# accessmode = "proxy"
# height = "280"
# width = "640"
# enableLink = "yes"
# debug = "0"
# authentication = "token"
# apitoken = "=="
# proxytimeout = "5"
# usepublic = "yes"
# publichost = "localhost/grafana/"
# publicprotocol = "http"

