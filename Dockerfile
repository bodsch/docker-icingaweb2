
FROM alpine:edge

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

LABEL version="1.0.1"

ENV TERM xterm

EXPOSE 80

# ---------------------------------------------------------------------------------------

RUN \
  echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >>  /etc/apk/repositories

RUN \
  apk --quiet update && \
  apk --quiet upgrade

RUN \
  rm -Rf /var/run && \
  ln -s /run /var/run

RUN \
  apk --quiet add \
    bash \
    curl \
    supervisor \
    pwgen \
    netcat-openbsd \
    php-fpm \
    php-pdo \
    php-pdo_mysql \
    php-xml \
    php-dom \
    php-mysqli \
    php-json \
    nginx \
    mysql-client \
    shadow@testing \
    icingaweb2@testing &&\
  rm -rf /var/cache/apk/*

RUN \
  usermod -G nginx,icingacmd nginx

RUN \
  mkdir /run/nginx && \
  mkdir /var/log/php-fpm && \
  mkdir /etc/icingaweb2/modules && \
  mkdir /etc/icingaweb2/enabledModules

ADD rootfs/ /

VOLUME  ["/etc/icingaweb2" ]

# Initialize and run Supervisor
ENTRYPOINT [ "/opt/startup.sh" ]

# ---------------------------------------------------------------------------------------
