#!/bin/bash

set -e

pushd $PWD

cd $(dirname $(readlink -f "$0"))

echo $PWD

if [[ -f modules.json ]]
then
  MODULE_JSON=$(cat ./modules.json)
else
  MODULE_JSON='{
    "Icinga/icingaweb2-module-director": {},
    "Icinga/icingaweb2-module-vsphere": {},
    "Icinga/icingaweb2-module-graphite": {},
    "Icinga/icingaweb2-module-generictts": {},
    "Icinga/icingaweb2-module-businessprocess": {},
    "Icinga/icingaweb2-module-elasticsearch": {},
    "Icinga/icingaweb2-module-cube": {},
    "Icinga/icingaweb2-module-aws": {},
    "Icinga/icingaweb2-module-fileshipper": {},
    "https://github.com/Icinga/icingaweb2-module-toplevelview": {},
    "http://github.com/Mikesch-mp/icingaweb2-module-grafana.git": {},
    "https://github.com/Mikesch-mp/icingaweb2-module-globe": {},
    "nbuchwitz/icingaweb2-module-map": {},
    "Thomas-Gelf/icingaweb2-module-vspheredb": {
      "enable": "false"
    },
    "morgajel/icingaweb2-module-boxydash": {}
  }'
fi

GITHUB_USER=${GITHUB_USER:-bodsch}

if [[ -z ${GITHUB_OAUTH_TOKEN} ]]
then
  echo "please set an OAuth token for GitHub API access"
  exit 1
fi

remaining=$(curl \
  --silent \
  --include \
  --user ${GITHUB_USER}:${GITHUB_OAUTH_TOKEN} \
  https://api.github.com/users/bodsch | grep "X-RateLimit-Remaining: " | awk -F 'X-RateLimit-Remaining: ' '{print $2}')

if [[ "${remaining/$'\r'/}" -gt 20 ]]
then

  echo " - get latest published versions"

  #current_time=$(date +%s)

  for k in $(echo ${MODULE_JSON} | jq -r '. | to_entries | .[] | .key')
  do
    enable="$(echo "${MODULE_JSON}" | jq -r ".[\"$k\"].enable")"
    use_git="$(echo "${MODULE_JSON}" | jq -r ".[\"$k\"].use_git")"
    [[ "${enable}" == null ]] && enable=true
    [[ "${use_git}" == null ]] && use_git=false

    project="$(echo "${k}" | sed -e 's|\.git||g' -e 's/https\?:\/\///' -e 's|github.com/||g')"
    project_maintainer="$(echo "${project}" | cut -d "/" -f1)"
    project_name="$(echo "${project}" | cut -d "/" -f2 | sed -e 's|icingaweb2-module-||g')"
    outfile=$(echo "${project}" | tr [:upper:] [:lower:] | sed -e 's|/|_|g')

  #  if [[ -f "/build/cache/github_${outfile}.json" ]]
  #  then
  #    file_time=$(stat -c '%Y' "/build/cache/github_${outfile}.json")
  #
  #    echo "${file_time}"
  #
  #    if (( file_time < ( current_time - ( 60 * 60 * 24 * 10 ) ) )); then
  #      echo "cached file for github_${outfile}.json is older than 10 days"
  #    else
  #      echo "use cached file"
  #      cp -v /build/cache/github_${outfile}.json /tmp/
  #    fi
  #  else
  #    echo "no cache"
  #  fi

    if [[ ! -f "cache/github_${outfile}.json" ]]
    then
      code=$(curl \
        --silent \
        --header 'Accept: application/vnd.github.v3.full+json' \
        --user ${GITHUB_USER}:${GITHUB_OAUTH_TOKEN} \
        --write-out "%{http_code}\n" \
        --out "cache/github_${outfile}.json" \
        https://api.github.com/repos/${project}/releases/latest)

  #    if [[ ${code} != 200 ]]
  #    then
  #      rm -f cache/github_${outfile}.json
  #    fi
    fi

    if [[ -f "cache/github_${outfile}.json" ]] && [[ $(stat -c %s cache/github_${outfile}.json) -gt 0 ]]
    then
      # remove some unneeded parts
      # and add our things
      cat "cache/github_${outfile}.json" | \
        jq 'del(.author) | del(.body_html) | del(.body_text) | del(.body) | del(.assets)' | \
        jq ". |= .+ {\"enable\": \"${enable}\", \"use_git\": \"${use_git}\", \"project_maintainer\": \"${project_maintainer}\", \"project_name\": \"${project_name}\" }" > cache/github_${outfile}.json_TMP
      mv cache/github_${outfile}.json_TMP cache/github_${outfile}.json
    fi
  done

else
  echo "sorry, API rate limit fot github exceeded. (only ${remaining} left)"
fi

tar -czf cache.tgz cache

popd

ls -l1 build
