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

    echo " - ${project_maintainer} :: ${project_name} ${version} (${release})"

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
        find . -mindepth 1 -maxdepth 1 -type d -name "*${project_name}*" -exec mv {} ${MODULE_DIRECTORY}/${project_name} \;

        rm -f ${project_name}.tgz
        mkdir /etc/icingaweb2/modules/${project_name}
      fi

    else
      [[ -d icingaweb2-module-${project_name} ]] && rm -rf icingaweb2-module-${project_name}
      git clone \
        --quiet \
        https://github.com/${project_maintainer}/icingaweb2-module-${project_name} > /dev/null

      [[ -d ${MODULE_DIRECTORY} ]] || continue

      mv icingaweb2-module-${project_name} ${MODULE_DIRECTORY}/${project_name}

      # install PHP dependency
      #
#      if [[ -e ${MODULE_DIRECTORY}/${project_name}/composer.json ]]
#      then
#        pushd ${MODULE_DIRECTORY}/${project_name}
#
#        /usr/bin/composer install
#
#        popd
#      fi
    fi

    if [[ "${enable}" = "true" ]]
    then
      /usr/bin/icingacli module enable ${project_name} 2> /dev/null
    fi
  done

  find ${MODULE_DIRECTORY} -name ".git*" -exec rm -rf {} 2> /dev/null \; || true

else
  echo "no cached github information found"
fi
