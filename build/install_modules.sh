#!/bin/bash
#
# install a set of icingaweb2 modules

set -e

[[ "${INSTALL_MODULES}" = "false" ]] && exit 0

echo "install icingaweb2 modules"

MODULE_DIRECTORY="/usr/share/webapps/icingaweb2/modules"

cd /build

if [[ -f cache.tgz ]]
then
  tar -xzf cache.tgz

  cd cache

  for file in $(ls -1 github_*.json)
  do

    published_at=$(jq --raw-output ".published_at" ${file})
    project_name=$(jq --raw-output ".project_name" ${file})
    project_maintainer=$(jq --raw-output ".project_maintainer" ${file})
    author=$(jq --raw-output ".author.login" ${file})
    version=$(jq --raw-output ".tag_name" ${file})
    url=$(jq --raw-output ".tarball_url" ${file})
    enable=$(jq --raw-output ".enable" ${file})
    use_git=$(jq --raw-output ".use_git" ${file})
    destination=$(jq --raw-output ".destination" ${file})

    [[ "${destination}" == null ]] && destination=

    if [[ ${published_at} != null ]]
    then
      if [[ -e /etc/alpine-release ]]
      then
        release_date=$(date -d @$(date -u -D %Y-%m-%dT%TZ -d "${published_at}" +%s) +%d.%m.%Y)
      else
        release_date=$(date -d ${published_at} +%d.%m.%Y)
      fi

      release="released at ${release_date}"

      if [[ "${use_git}" == "true" ]]
      then
        release="${release} but use git"
      fi

    else
      version=""
      release="never released, use git"
    fi

    echo " - ${project_name} ${version} (${release}) (${project_maintainer})"

    if [[ ${url} != null ]] && [[ "${use_git}" = "false" ]]
    then
      if [[ ! -f "${project_name}.tgz" ]]
      then
      curl \
        --silent \
        --location \
        --retry 3 \
        --output "${project_name}.tgz" \
        ${url}
      fi

      if [[ -f "${project_name}.tgz" ]]
      then
        [[ -d ${MODULE_DIRECTORY} ]] || continue

        tar -xzf ${project_name}.tgz

        if [[ ! -z ${destination} ]]
        then
          [[ -d ${destination} ]] || mkdir -p ${destination}

          find . -mindepth 1 -maxdepth 1 -type d -name "*${project_name}*" -exec mv {} ${project_name} \;
          mv ${project_name}/* ${destination}/
          rm -f ${project_name}.tgz
        else
          find . -mindepth 1 -maxdepth 1 -type d -name "*${project_name}*" -exec mv {} ${MODULE_DIRECTORY}/${project_name} \;

          rm -f ${project_name}.tgz
          mkdir /etc/icingaweb2/modules/${project_name}
        fi
      fi

    else

      [[ -d icingaweb2-module-${project_name} ]] && rm -rf icingaweb2-module-${project_name}
      git clone \
        --quiet \
        https://github.com/${project_maintainer}/icingaweb2-module-${project_name} > /dev/null

      [[ -d ${MODULE_DIRECTORY} ]] || continue

      # install PHP dependency
      #
      if [[ -e "icingaweb2-module-${project_name}/composer.json" ]]
      then
#        echo "found composer.json"
        pushd icingaweb2-module-${project_name} > /dev/null

        /usr/bin/composer install > /dev/null 2> /dev/null

        popd > /dev/null
      fi

      mv icingaweb2-module-${project_name} ${MODULE_DIRECTORY}/${project_name}
    fi

    if [[ "${enable}" = "true" ]] && [[ -d ${MODULE_DIRECTORY}/${project_name} ]]
    then
      /usr/bin/icingacli module enable ${project_name} 2> /dev/null
    fi

  done

  find ${MODULE_DIRECTORY} -name ".git*" -exec rm -rf {} 2> /dev/null \; || true

else
  echo "no cached github information found"
fi
