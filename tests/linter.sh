#!/bin/bash

set -e

HADOLINT_VERSION='1.14.0'
HADOLINT_PATH='/usr/local/bin/hadolint'

if ! [[ -x "$(command -v hadolint)" ]]
then
  sudo curl \
    --silent \
    --location \
    --output "${HADOLINT_PATH}" \
    "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64"
  sudo chmod +x "${HADOLINT_PATH}"
fi

#if ! [[ -x "$(command -v shellcheck)" ]]
#then
#  docker pull koalaman/shellcheck:stable  # Or :v0.4.7 for that version, or :latest for daily builds
#  alias shellcheck="docker run -v "$PWD:/mnt" koalaman/shellcheck "
#fi

hadolint Dockerfile
# shellcheck docker-entrypoint.sh -x
