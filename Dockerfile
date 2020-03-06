FROM debian:buster-slim as stage1

ARG VCS_REF
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_TYPE
ARG ICINGAWEB_VERSION
ARG INSTALL_THEMES
ARG INSTALL_MODULES

ENV \
  TERM=xterm \
  DEBIAN_FRONTEND=noninteractive \
  TZ='Europe/Berlin'

# ---------------------------------------------------------------------------------------

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  chsh -s /bin/bash && \
  ln -sf /bin/bash /bin/sh && \
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  ln -s  /etc/default /etc/sysconfig && \
  apt-get remove \
    --allow-remove-essential \
    --assume-yes \
    --purge \
      e2fsprogs libext2fs2 && \
  apt-get update && \
  apt-get install \
    --assume-yes \
    --no-install-recommends \
      apt-utils lsb-release && \
  apt-get dist-upgrade \
    --assume-yes && \
  apt-get install \
    --assume-yes \
      apt-transport-https \
      ca-certificates \
      curl \
      wget \
      gnupg > /dev/null && \
  curl \
    --silent \
    https://packages.icinga.com/icinga.key | apt-key add - && \
  . /etc/os-release && \
  if [ "${ID}" = "ubuntu" ]; then \
    if [ -n "${UBUNTU_CODENAME+x}" ]; then \
      DIST="${UBUNTU_CODENAME}"; \
    else \
      DIST="$(lsb_release -c | awk '{print $2}')"; \
    fi \
  elif [ "${ID}" = "debian" ]; then \
    DIST=$(awk -F"[)(]+" '/VERSION=/ {print $2}' /etc/os-release) ;\
  fi && \
  echo " => ${ID} - ${DIST}" && \
  echo "deb http://packages.icinga.com/${ID} icinga-${DIST} main" > "/etc/apt/sources.list.d/${DIST}-icinga.list" && \
  curl https://packages.sury.org/php/apt.gpg | apt-key add -; \
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list && \
  apt-get update

# hadolint ignore=DL3018
RUN \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  curl \
  composer \
  jq \
  git \
  php7.3 \
  php7.3-ctype \
  php7.3-intl \
  php7.3-gettext

COPY build /build

WORKDIR /tmp

# hadolint ignore=DL3003,DL4006
RUN \
  mkdir /usr/share/webapps && \
  if [ -z "${BUILD_TYPE}" ] || [ "${BUILD_TYPE}" = "stable" ] ; then \
    echo "install icingaweb2 v${ICINGAWEB_VERSION}" && \
    curl \
      --silent \
      --location \
      --retry 3 \
      --cacert /etc/ssl/certs/ca-certificates.crt \
      "https://github.com/Icinga/icingaweb2/archive/v${ICINGAWEB_VERSION}.tar.gz" \
      | gunzip \
      | tar x -C /usr/share/webapps/ && \
    ln -s "/usr/share/webapps/icingaweb2-${ICINGAWEB_VERSION}" /usr/share/webapps/icingaweb2 ; \
  else \
    echo "install icingaweb2 from git " && \
    git clone https://github.com/Icinga/icingaweb2.git && \
    cd icingaweb2 && \
    version=$(git describe --tags --always | sed 's/^v//') && \
    echo "  version: ${version}" && \
    rm -rf /tmp/icingaweb2/.git* && \
    rm -rf /tmp/icingaweb2/.puppet && \
    mv /tmp/icingaweb2 /usr/share/webapps/ ; \
  fi

RUN \
  ln -s /usr/share/webapps/icingaweb2/bin/icingacli /usr/bin/icingacli && \
  mkdir -p /var/log/icingaweb2 && \
  mkdir -p /etc/icingaweb2/modules && \
  mkdir -p /etc/icingaweb2/enabledModules

#RUN \
#  /build/install_modules.sh

#RUN \
#  /build/install_themes.sh

COPY build/icingaweb2-modules /usr/share/webapps/icingaweb2/modules/
COPY build/icingaweb2-themes  /usr/share/webapps/icingaweb2/modules/

RUN \
  /build/install_themes.sh

# ---------------------------------------------------------------------------------------

FROM debian:buster-slim as final

ARG VCS_REF
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_TYPE
ARG ICINGAWEB_VERSION
ARG INSTALL_THEMES
ARG INSTALL_MODULES

ENV \
  TERM=xterm \
  DEBIAN_FRONTEND=noninteractive \
  TZ='Europe/Berlin'

COPY --from=stage1 /usr/share/webapps              /usr/share/webapps
COPY --from=stage1 /etc/icingaweb2                 /etc/icingaweb2

RUN \
  apt-get update && apt-get install -y locales && \
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
  locale-gen && update-locale LANG=en_US.UTF-8

# hadolint ignore=DL3017,DL3018
RUN \
  chsh -s /bin/bash && \
  ln -sf /bin/bash /bin/sh && \
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  ln -s  /etc/default /etc/sysconfig && \
  apt-get remove \
    --allow-remove-essential \
    --assume-yes \
    --purge \
      e2fsprogs libext2fs2 && \
  apt-get update && \
  apt-get install \
    --assume-yes \
    --no-install-recommends \
      apt-utils lsb-release && \
  apt-get dist-upgrade \
    --assume-yes && \
  apt-get install \
    --assume-yes \
      apt-transport-https \
      ca-certificates \
      curl \
      wget \
      gnupg > /dev/null && \
  curl \
    --silent \
    https://packages.icinga.com/icinga.key | apt-key add - && \
  . /etc/os-release && \
  if [ "${ID}" = "ubuntu" ]; then \
    if [ -n "${UBUNTU_CODENAME+x}" ]; then \
      DIST="${UBUNTU_CODENAME}"; \
    else \
      DIST="$(lsb_release -c | awk '{print $2}')"; \
    fi \
  elif [ "${ID}" = "debian" ]; then \
    DIST=$(awk -F"[)(]+" '/VERSION=/ {print $2}' /etc/os-release) ;\
  fi && \
  echo " => ${ID} - ${DIST}" && \
  echo "deb http://packages.icinga.com/${ID} icinga-${DIST} main" > "/etc/apt/sources.list.d/${DIST}-icinga.list" && \
  curl https://packages.sury.org/php/apt.gpg | apt-key add -; \
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list && \
  apt-get update

RUN \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    dnsutils \
    dos2unix \
    inotify-tools \
    jq \
    locales \
    mariadb-client \
    nano \
    nginx \
    netcat-openbsd \
    openssl \
    php7.3 \
    php7.3-cli \
    php7.3-common \
    php7.3-ctype \
    php7.3-fpm \
    php7.3-mysql \
    php7.3-intl \
    php7.3-ldap \
    php7.3-gettext \
    php7.3-json \
    php7.3-mbstring \
    php7.3-curl \
    php7.3-iconv \
    php7.3-xml \
    php7.3-dom \
    php7.3-soap \
    php7.3-sockets \
    php7.3-posix \
    php7.3-gmp \
    php-yaml \
    php-xdebug \
    procps \
    python-yaml \
    tzdata \
    pwgen \
    yajl-tools && \
  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  sed -i -e 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen && \
  sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  locale-gen && update-locale LANG=en_US.UTF-8 && \
  ln -s /usr/share/webapps/icingaweb2/bin/icingacli /usr/bin/icingacli && \
  mkdir -p /var/log/icingaweb2 && \
  /usr/bin/icingacli module disable setup && \
  /usr/bin/icingacli module enable monitoring  2> /dev/null && \
  /usr/bin/icingacli module enable translation 2> /dev/null && \
  /usr/bin/icingacli module enable doc         2> /dev/null && \
  mkdir /run/php && \
  mkdir /var/log/php-fpm && \
  rm /etc/nginx/sites-enabled/default && \
  rm -rf /build && rm -rf /tmp/*

COPY rootfs/ /

WORKDIR /etc/icingaweb2

VOLUME ["/etc/icingaweb2", "/usr/share/webapps/icingaweb2", "/init/custom.d"]

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail http://localhost/health || exit 1

CMD ["/init/run.sh"]

# ---------------------------------------------------------------------------------------

# Build-time metadata as defined at http://label-schema.org
LABEL \
  version=${BUILD_VERSION} \
  maintainer="Michael Siebertz <s_michael1@gmx.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="IcingaWeb2 Docker Image" \
  org.label-schema.description="Inofficial IcingaWeb2 Docker Image" \
  org.label-schema.url="https://www.icinga.org/" \
  org.label-schema.vcs-ref=${VCS_REF} \
  org.label-schema.vcs-url="https://gitlab.com/olemisea/icingaweb2" \
  org.label-schema.vendor="Michael Siebertz" \
  org.label-schema.version=${ICINGAWEB_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="GNU General Public License v3.0"

# ---------------------------------------------------------------------------------------
