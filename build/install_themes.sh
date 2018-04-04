#!/bin/bash
#
# install a set of icingaweb2 themes

[[ "${INSTALL_THEMES}" = "false" ]] && exit 0

MODULE_DIRECTORY="/usr/share/webapps/icingaweb2/modules"

cd /tmp

echo "install theme 'unicorn' (mikesch)"
git clone https://github.com/Mikesch-mp/icingaweb2-theme-unicorn 2> /dev/null
mkdir ${MODULE_DIRECTORY}/unicorn
mv /tmp/icingaweb2-theme-unicorn/public ${MODULE_DIRECTORY}/unicorn/
curl \
  --silent \
  --location \
  --retry 3 \
  --output ${MODULE_DIRECTORY}/unicorn/public/img/unicorn.png \
  http://i.imgur.com/SCfMd.png
/usr/bin/icingacli module enable unicorn

echo "install theme 'lsd' (mikesch)"
git clone https://github.com/Mikesch-mp/icingaweb2-theme-lsd 2> /dev/null
mkdir ${MODULE_DIRECTORY}/lsd
mv /tmp/icingaweb2-theme-lsd/public ${MODULE_DIRECTORY}/lsd/
/usr/bin/icingacli module enable lsd

echo "install theme 'april' (mikesch)"
git clone https://github.com/Mikesch-mp/icingaweb2-theme-april 2> /dev/null
mkdir ${MODULE_DIRECTORY}/april
mv /tmp/icingaweb2-theme-april/public ${MODULE_DIRECTORY}/april/
/usr/bin/icingacli module enable april

echo "install theme 'company' (Icinga)"
git clone https://github.com/Icinga/icingaweb2-theme-company 2> /dev/null
mkdir ${MODULE_DIRECTORY}/company
mv /tmp/icingaweb2-theme-company/public ${MODULE_DIRECTORY}/company/
/usr/bin/icingacli module enable company

echo "install theme 'batman' (jschanz)"
git clone https://github.com/jschanz/icingaweb2-theme-batman 2> /dev/null
mkdir ${MODULE_DIRECTORY}/batman
mv /tmp/icingaweb2-theme-batman/public ${MODULE_DIRECTORY}/batman/
curl \
  --silent \
  --location \
  --retry 3 \
  --output ${MODULE_DIRECTORY}/batman/public/img/batman.jpg \
  https://unsplash.com/photos/meqVd5zwylI
curl \
  --silent \
  --location \
  --retry 3 \
  --output ${MODULE_DIRECTORY}/batman/public/img/batman.svg \
  https://www.shareicon.net/download/2015/09/24/106444_man.svg
/usr/bin/icingacli module enable batman

echo "install theme 'nordlicht' (sysadmama)"
git clone https://github.com/sysadmama/icingaweb2-theme-nordlicht 2> /dev/null
mkdir ${MODULE_DIRECTORY}/nordlicht
mv /tmp/icingaweb2-theme-nordlicht/public ${MODULE_DIRECTORY}/nordlicht/
/usr/bin/icingacli module enable nordlicht

echo "install theme 'spring' (dnsmichi)"
git clone https://github.com/dnsmichi/icingaweb2-theme-spring 2> /dev/null
mkdir ${MODULE_DIRECTORY}/spring
mv /tmp/icingaweb2-theme-spring/public ${MODULE_DIRECTORY}/spring/
/usr/bin/icingacli module enable spring

