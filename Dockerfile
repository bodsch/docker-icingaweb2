
FROM alpine:3.8 as builder

RUN \
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --no-cache \
    bash \
    ca-certificates \
    curl \
    file \
    git \
    g++ \
    make \
    jq \
    mysql-client \
    nginx \
    netcat-openbsd \
    openssl \
    php7 \
    php7-ctype \
    php7-dev \
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
    php7-soap \
    php7-posix \
    pwgen \
    yaml \
    yaml-dev \
    yajl-tools

RUN \
  cd /tmp && \
  curl \
    --silent \
    --location \
    --retry 3 \
    --cacert /etc/ssl/certs/ca-certificates.crt \
    --out yaml.tgz \
    https://pecl.php.net/get/yaml

RUN \
  cd /tmp && \
  tar -xzf yaml.tgz && \
  cd yaml-* && \
  phpize && \
  ./configure && \
  make && \
  make install

CMD "/bin/bash"

# ---------------------------------------------------------------------------------------

FROM alpine:3.8

EXPOSE 80

ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_TYPE
ARG ICINGAWEB_VERSION
ARG INSTALL_THEMES
ARG INSTALL_MODULES

ENV \
  TERM=xterm

# ---------------------------------------------------------------------------------------

COPY build /build
COPY --from=builder /usr/lib/php7/modules/yaml.so /usr/lib/php7/modules/

RUN \
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --no-cache --virtual .build-deps \
    git shadow tzdata && \
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
    php7-soap \
    php7-posix \
    pwgen \
    yaml \
    yajl-tools && \
  cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
  echo "extension=yaml.so" > /etc/php7/conf.d/ext-yaml.ini && \
  [ -e /usr/bin/php ]     || ln -s /usr/bin/php7      /usr/bin/php && \
  [ -e /usr/bin/php-fpm ] || ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
  sed -i -e '/^#/ d' -e '/^;/ d'  -e '/^ *$/ d' /etc/php7/php.ini && \
  mkdir /usr/share/webapps && \
  if ( [ -z ${BUILD_TYPE} ] || [ "${BUILD_TYPE}" == "stable" ] ) ; then \
    echo "install 'icingaweb2' v${ICINGAWEB_VERSION}" && \
    curl \
      --silent \
      --location \
      --retry 3 \
      --cacert /etc/ssl/certs/ca-certificates.crt \
      https://github.com/Icinga/icingaweb2/archive/v${ICINGAWEB_VERSION}.tar.gz \
      | gunzip \
      | tar x -C /usr/share/webapps/ && \
    ln -s /usr/share/webapps/icingaweb2-${ICINGAWEB_VERSION} /usr/share/webapps/icingaweb2 ; \
  else \
    echo "install 'icingaweb2' from git " && \
    cd /tmp && \
    git clone https://github.com/Icinga/icingaweb2.git && \
    cd icingaweb2 && \
    version=$(git describe --tags --always | sed 's/^v//') && \
    echo "  version: ${version}" && \
    mv /tmp/icingaweb2 /usr/share/webapps/ && \
    rm -rf /usr/share/webapps/icingaweb2/.git* && \
    rm -rf /usr/share/webapps/icingaweb2/.puppet ; \
  fi && \
  ln -s /usr/share/webapps/icingaweb2/bin/icingacli /usr/bin/icingacli && \
  mkdir -p /var/log/icingaweb2 && \
  mkdir -p /etc/icingaweb2/modules && \
  mkdir -p /etc/icingaweb2/enabledModules && \
  /build/install_modules.sh && \
  /build/install_themes.sh && \
  /usr/bin/icingacli module disable setup      2> /dev/null && \
  /usr/bin/icingacli module enable monitoring  2> /dev/null && \
  /usr/bin/icingacli module enable translation 2> /dev/null && \
  /usr/bin/icingacli module enable doc         2> /dev/null && \
  mkdir /run/nginx && \
  mkdir /var/log/php-fpm && \
  apk del --quiet .build-deps && \
  rm -rf \
    /build \
    /tmp/* \
    /var/cache/apk/*

COPY rootfs/ /

WORKDIR /etc/icingaweb2

VOLUME [ "/etc/icingaweb2" "/usr/share/webapps/icingaweb2" ]

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail http://localhost/health || exit 1

CMD [ "/init/run.sh" ]

# ---------------------------------------------------------------------------------------

# Build-time metadata as defined at http://label-schema.org
LABEL \
  version=${BUILD_VERSION} \
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
