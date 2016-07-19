FROM bodsch/docker-alpine-base:3.4

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

LABEL version="1.1.1"

ENV TERM xterm

EXPOSE 80

# ---------------------------------------------------------------------------------------

RUN \
  apk --quiet --no-cache update && \
  apk --quiet --no-cache add \
    bash \
    git \
    pwgen \
    netcat-openbsd \
    icingaweb2 \
    php5-fpm \
    php5-pdo \
    php5-pdo_mysql \
    php5-xml \
    php5-dom \
    php5-mysqli \
    php5-json \
    nginx \
    mysql-client \
    shadow \
    openssl && \
  cd /usr/share/webapps/icingaweb2/modules && \
  git clone https://github.com/Icinga/icingaweb2-module-director.git director && \
  git clone https://github.com/Icinga/icingaweb2-module-graphite.git graphite && \
  git clone https://github.com/Icinga/icingaweb2-module-generictts.git generictts && \
  usermod -G nginx,icingacmd nginx && \
  mkdir /run/nginx && \
  mkdir /var/log/php-fpm && \
  mkdir /etc/icingaweb2/modules && \
  mkdir /etc/icingaweb2/modules/graphite && \
  mkdir /etc/icingaweb2/modules/generictts && \
  mkdir /etc/icingaweb2/enabledModules && \
  /usr/bin/icingacli module enable monitoring && \
  /usr/bin/icingacli module enable setup && \
  /usr/bin/icingacli module enable translation && \
  /usr/bin/icingacli module enable doc && \
  /usr/bin/icingacli module enable director && \
  /usr/bin/icingacli module enable graphite && \
  /usr/bin/icingacli module enable generictts && \
  apk del --purge \
    git && \
  rm -rf /var/cache/apk/*

ADD rootfs/ /

VOLUME  ["/etc/icingaweb2" ]

ENTRYPOINT [ "/opt/startup.sh" ]

# ---------------------------------------------------------------------------------------
