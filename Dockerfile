# download and prepare web modules
FROM    node:13 AS WEBMODULES
ADD     /build/web_modules /build
RUN     npm install --global bower \
&&      cd /build \
&&      bower install --allow-root


# assemble container
FROM    debian:buster-slim

# image config
EXPOSE  80 8888
WORKDIR /etc/icingaweb2

# variables
ENV     PHP_VERSION="7.3" \
        DEBIAN_FRONTEND="noninteractive" \
        TZ='Europe/Berlin' \
        APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="1"

# install basic required utils
RUN     chsh -s /bin/bash \
&&      ln -sf /bin/bash /bin/sh \
&&      apt-get update \
&&      apt-get -y install --no-install-recommends \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release \
                tzdata \
                wget \
# add icinga2 repo
&&      wget -O - https://packages.icinga.com/icinga.key | apt-key add - \
&&      echo "deb https://packages.icinga.com/debian icinga-$(lsb_release -sc) main" > /etc/apt/sources.list.d/icinga.list \
&&      echo "deb-src https://packages.icinga.com/debian icinga-$(lsb_release -sc) main" >> /etc/apt/sources.list.d/icinga.list \
# add nginx repo
&&      echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" \
        | tee /etc/apt/sources.list.d/nginx.list \
&&      curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - \
# add mariadb repo
&&      wget -O - https://mariadb.org/mariadb_release_signing_key.asc | apt-key add - \
&&      echo "deb [arch=amd64] http://mirror.netcologne.de/mariadb/repo/10.4/debian $(lsb_release -sc) main" >> /etc/apt/sources.list.d/mariadb.list \
#
# add php repo
&&      wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
&&      echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
# install basic required utils
RUN     chsh -s /bin/bash \
&&      apt-get update \
&&      apt-get -y install --no-install-recommends \
                bind9-host \
                dnsutils \
                dos2unix \
                gettext-base \
                inotify-tools \
                jq \
                locales \
                mariadb-client \
                netcat-openbsd \
                openssl \
                python-yaml \
                procps \
                pwgen \
                yajl-tools \
&&      sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
&&      sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
&&      dpkg-reconfigure --frontend=noninteractive locales \
&&      locale-gen && update-locale LANG=en_US.UTF-8 \
#
# add s6
&&      curl -L https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz \
        | tar xz -C / \
#
#
# install nginx + php
&&      apt-get install -y --no-install-recommends \
                nginx \
                php${PHP_VERSION} \
                php${PHP_VERSION}-cli \
                php${PHP_VERSION}-fpm \
                php${PHP_VERSION}-ctype \
                php${PHP_VERSION}-intl \
                php${PHP_VERSION}-json \
                php${PHP_VERSION}-gettext \
                php${PHP_VERSION}-readline \
                php${PHP_VERSION}-opcache \
                php${PHP_VERSION}-mbstring \
                php${PHP_VERSION}-xml \
                php${PHP_VERSION}-curl \
                php${PHP_VERSION}-mysql \
                php${PHP_VERSION}-pgsql \
                php${PHP_VERSION}-gmp \
                php${PHP_VERSION}-yaml \
                php${PHP_VERSION}-ldap \
#
# install icinga2 web packages
&&      apt-get install -y --no-install-recommends \
                icingacli \
                icingaweb2 \
                icingaweb2-module-monitoring \
#
# cleanup apt mess
&&      apt-get clean \
&&      rm -rf \
                /var/lib/apt/lists/* \
                /tmp/* \
                /var/tmp/*

# install icinga modules + themes
COPY    --from=WEBMODULES /build/modules /usr/share/icingaweb2/modules

# create clean web root dir
RUN     mkdir -p /etc/icingaweb2/enabledModules \
&&      mkdir -p /var/log/icingaweb2 \
&&      chown www-data:www-data -R /etc/icingaweb2/ \
&&      chown www-data:www-data -R /var/log/icingaweb2 \
#
# remove default nginx site and confs
&&      rm -f /etc/nginx/sites-enabled/* \
&&      rm -f /etc/nginx/conf.d/* \
#
# symlink php version to current
&&      ln -s /etc/php/${PHP_VERSION} /etc/php/cur \
#
# configure php-fpm
&&      cd /etc/php/${PHP_VERSION}/fpm \
&&      mv php-fpm.conf php-fpm.conf.bak \
#
# disable original config
&&      rm pool.d/www.conf

# TODO revert once old init is fixed
RUN     mv /init /init-s6
ENTRYPOINT [ "/init-s6" ]

# install services, scripts, config
ADD     services.d      /etc/services.d
ADD     php-fpm         /etc/php/${PHP_VERSION}/fpm/
ADD     nginx           /etc/nginx/
ADD     cont-init.d     /etc/cont-init.d/
ADD     icingaweb2      /etc/icingaweb2
ADD     init            /init

# fill in php version
RUN     envsubst '${PHP_VERSION}' < /etc/php/${PHP_VERSION}/fpm/php-fpm.conf.tpl > /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
&&      rm /etc/php/${PHP_VERSION}/fpm/php-fpm.conf.tpl \
&&      envsubst '${PHP_VERSION}' < /etc/services.d/php-fpm/run.tpl > /etc/services.d/php-fpm/run \
&&      rm /etc/services.d/php-fpm/run.tpl
