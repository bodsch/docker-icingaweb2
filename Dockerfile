
FROM debian:jessie

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

LABEL version="0.9.6"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm

EXPOSE 80

# ---------------------------------------------------------------------------------------

RUN apt-get -qq update && \
  apt-get -qqy install \
    ca-certificates \
    wget \
    software-properties-common && \
  wget --quiet -O - https://packages.icinga.org/icinga.key | apt-key add - && \
  echo "deb http://packages.icinga.org/debian icinga-jessie-snapshots main" >> /etc/apt/sources.list.d/icinga.list && \
  apt-get -qq update && \
  apt-get -qqy upgrade && \
  apt-get -qqy dist-upgrade && \
  apt-get -qqy install --no-install-recommends \
    supervisor \
    pwgen \
    nano \
    netcat \
    nginx \
    mysql-client \
    icingaweb2 \
    icingaweb2-module-monitoring \
    php-icinga \
    php-htmlpurifier \
    php-dompdf \
    php5 \
    php5-cli \
    php5-fpm \
    php5-common \
    php5-gd \
    php5-json \
    php5-mysql \
    php5-apcu && \
  apt-get clean  && \
  rm -rf /var/lib/apt/lists/* && \
  rm -f /etc/nginx/sites-enabled/default /etc/php5/fpm/pool.d/www.conf 2> /dev/null && \
  mkdir -p /var/log/nginx/icingaweb /var/log/php-fpm/worker-01

ADD rootfs/ /

VOLUME  ["/etc/icingaweb2" ]

# Initialize and run Supervisor
ENTRYPOINT [ "/opt/startup.sh" ]

# ---------------------------------------------------------------------------------------
