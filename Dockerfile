
FROM alpine:3.7

ENV \
  TERM=xterm \
  BUILD_DATE="2018-01-26" \
  ICINGAWEB_VERSION="2.5.1"

EXPOSE 80

# Build-time metadata as defined at http://label-schema.org
LABEL \
  version="1801" \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
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
    yajl-tools && \
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
  MODULE_DIRECTORY="/usr/share/webapps/icingaweb2/modules" && \
  cd ${MODULE_DIRECTORY} && \
  git clone https://github.com/Icinga/icingaweb2-module-director        --single-branch director && \
  git clone https://github.com/Icinga/icingaweb2-module-graphite        --single-branch graphite && \
  git clone https://github.com/Icinga/icingaweb2-module-generictts      --single-branch generictts && \
  git clone https://github.com/Icinga/icingaweb2-module-businessprocess --single-branch businessprocess && \
  git clone https://github.com/Icinga/icingaweb2-module-elasticsearch   --single-branch elasticsearch && \
  git clone https://github.com/Icinga/icingaweb2-module-cube            --single-branch cube && \
  git clone https://github.com/Mikesch-mp/icingaweb2-module-grafana     --single-branch grafana && \
  rm -rf ${MODULE_DIRECTORY}/*/.git* && \
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
  /usr/bin/icingacli module disable setup && \
  /usr/bin/icingacli module enable translation && \
  /usr/bin/icingacli module enable doc && \
  /usr/bin/icingacli module enable graphite && \
  /usr/bin/icingacli module enable cube && \
  /usr/bin/icingacli module enable grafana && \
  cd /tmp && \
  git clone https://github.com/Mikesch-mp/icingaweb2-theme-unicorn && \
  mkdir ${MODULE_DIRECTORY}/unicorn && \
  mv /tmp/icingaweb2-theme-unicorn/public ${MODULE_DIRECTORY}/unicorn/ && \
  curl \
    --silent \
    --location \
    --retry 3 \
    --output ${MODULE_DIRECTORY}/unicorn/public/img/unicorn.png \
    http://i.imgur.com/SCfMd.png && \
  git clone https://github.com/Icinga/icingaweb2-theme-company && \
  mkdir ${MODULE_DIRECTORY}/company && \
  mv /tmp/icingaweb2-theme-company/public ${MODULE_DIRECTORY}/company/ && \
  git clone https://github.com/jschanz/icingaweb2-theme-batman && \
  mkdir ${MODULE_DIRECTORY}/batman && \
  mv /tmp/icingaweb2-theme-batman/public ${MODULE_DIRECTORY}/batman/ && \
  curl \
    --silent \
    --location \
    --retry 3 \
    --output ${MODULE_DIRECTORY}/batman/public/img/batman.jpg \
    https://unsplash.com/photos/meqVd5zwylI && \
  curl \
    --silent \
    --location \
    --retry 3 \
    --output ${MODULE_DIRECTORY}/batman/public/img/batman.svg \
    https://www.shareicon.net/download/2015/09/24/106444_man.svg && \
  /usr/bin/icingacli module enable unicorn && \
  /usr/bin/icingacli module enable company && \
  /usr/bin/icingacli module enable batman && \
  mkdir /run/nginx && \
  mkdir /var/log/php-fpm && \
  apk del --quiet .build-deps && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY rootfs/ /

WORKDIR /etc/icingaweb2

VOLUME /etc/icingaweb2

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail http://localhost/health || exit 1

CMD [ "/init/run.sh" ]

# ---------------------------------------------------------------------------------------
