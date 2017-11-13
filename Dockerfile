
FROM alpine:3.6

MAINTAINER Bodo Schulz <bodo@boone-schulz.de>

ENV \
  ALPINE_MIRROR="mirror1.hs-esslingen.de/pub/Mirrors" \
  ALPINE_VERSION="v3.6" \
  TERM=xterm \
  BUILD_DATE="2017-11-13" \
  ICINGAWEB_VERSION="2.4.2"

EXPOSE 80

# Build-time metadata as defined at http://label-schema.org
LABEL \
  version="1711" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="IcingaWeb2 Docker Image" \
  org.label-schema.description="Inofficial IcingaWeb2 Docker Image" \
  org.label-schema.url="https://www.icinga.org/" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-icingaweb2" \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${ICINGAWEB_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="GNU General Public License v3.0"

# ---------------------------------------------------------------------------------------

RUN \
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --no-cache --virtual .build-deps \
    git shadow && \
  apk add --quiet --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    mysql-client \
    nginx \
    netcat-openbsd \
    openssl \
    php7 \
    php7-ctype \
    php7-fpm \
    php7-pdo_mysql \
    php7-openssl \
    php7-intl \
    php7-ldap \
    php7-gettext \
    php7-json \
    php7-mbstring \
    php7-curl \
    php7-iconv \
    php7-session \
    php7-xml \
    php7-dom \
    pwgen \
    shadow \
    supervisor && \
  [ -e /usr/bin/php ]     || ln -s /usr/bin/php7      /usr/bin/php && \
  [ -e /usr/bin/php-fpm ] || ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
  mkdir /usr/share/webapps && \
  echo "fetch: Icingaweb2 ${ICINGAWEB_VERSION}" && \
  curl \
    --silent \
    --location \
    --retry 3 \
    --cacert /etc/ssl/certs/ca-certificates.crt \
    "https://github.com/Icinga/icingaweb2/archive/v${ICINGAWEB_VERSION}.tar.gz" \
    | gunzip \
    | tar x -C /usr/share/webapps/ && \
  ln -s /usr/share/webapps/icingaweb2-${ICINGAWEB_VERSION} /usr/share/webapps/icingaweb2 && \
  ln -s /usr/share/webapps/icingaweb2/bin/icingacli /usr/bin/icingacli && \
  cd /usr/share/webapps/icingaweb2/modules && \
  git clone https://github.com/Icinga/icingaweb2-module-director.git        --single-branch director && \
  git clone https://github.com/Icinga/icingaweb2-module-graphite.git        --single-branch graphite && \
  git clone https://github.com/Icinga/icingaweb2-module-generictts.git      --single-branch generictts && \
  git clone https://github.com/Icinga/icingaweb2-module-businessprocess.git --single-branch businessprocess && \
  git clone https://github.com/Icinga/icingaweb2-module-elasticsearch.git   --single-branch elasticsearch && \
  git clone https://github.com/Icinga/icingaweb2-module-cube                --single-branch cube && \
  git clone https://github.com/Mikesch-mp/icingaweb2-module-grafana.git     --single-branch grafana && \
  rm -rf /usr/share/webapps/icingaweb2/modules/*/.git* && \
  mkdir -p /var/log/icingaweb2 && \
  mkdir -p /etc/icingaweb2/modules && \
  mkdir /etc/icingaweb2/modules/graphite && \
  mkdir /etc/icingaweb2/modules/generictts && \
  mkdir /etc/icingaweb2/modules/businessprocess && \
  mkdir /etc/icingaweb2/modules/cube && \
  mkdir /etc/icingaweb2/modules/grafana && \
  mkdir /etc/icingaweb2/enabledModules && \
  /usr/bin/icingacli module enable director && \
  /usr/bin/icingacli module enable businessprocess && \
  /usr/bin/icingacli module enable monitoring && \
  /usr/bin/icingacli module enable setup && \
  /usr/bin/icingacli module enable translation && \
  /usr/bin/icingacli module enable doc && \
  /usr/bin/icingacli module enable graphite && \
  /usr/bin/icingacli module enable cube && \
  /usr/bin/icingacli module enable grafana && \
  sed -i 's|font-size: 0.875em;|font-size: 1em;|g' /usr/share/webapps/icingaweb2/public/css/icinga/*.less && \
  sed -i 's|font-size: 0.750em;|font-size: 1em;|g' /usr/share/webapps/icingaweb2/public/css/icinga/*.less && \
  mkdir /run/nginx && \
  mkdir /var/log/php-fpm && \
  apk del --quiet .build-deps && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY rootfs/ /

WORKDIR "/etc/icingaweb2"

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail http://localhost/health || exit 1

CMD [ "/init/run.sh" ]

# ---------------------------------------------------------------------------------------
