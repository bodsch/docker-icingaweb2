
FROM bodsch/docker-alpine-base:1610-02

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

LABEL version="1.2.1"

ENV TERM xterm

EXPOSE 80

# ---------------------------------------------------------------------------------------

RUN \
  apk --no-cache update && \
  apk --no-cache upgrade && \
  apk --no-cache add \
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
  git clone https://github.com/Icinga/icingaweb2-module-businessprocess.git businessprocess && \
  git clone https://github.com/Icinga/icingaweb2-module-elasticsearch.git elasticsearch && \
  usermod --append --groups icinga,icingacmd nginx && \
  mkdir /run/nginx && \
  mkdir /var/log/php-fpm && \
  mkdir /etc/icingaweb2/modules && \
  mkdir /etc/icingaweb2/modules/graphite && \
  mkdir /etc/icingaweb2/modules/generictts && \
  mkdir /etc/icingaweb2/modules/businessprocess && \
  mkdir /etc/icingaweb2/enabledModules && \
  /usr/bin/icingacli module enable monitoring && \
  /usr/bin/icingacli module enable setup && \
  /usr/bin/icingacli module enable translation && \
  /usr/bin/icingacli module enable doc && \
  /usr/bin/icingacli module enable director && \
  /usr/bin/icingacli module enable graphite && \
  /usr/bin/icingacli module enable generictts && \
  /usr/bin/icingacli module enable businessprocess && \
  apk del --purge \
    git && \
  rm -rf /var/cache/apk/*

COPY rootfs/ /

VOLUME [ "/etc/icingaweb2" ]

CMD /opt/startup.sh"

# ---------------------------------------------------------------------------------------
