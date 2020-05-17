#!/bin/bash

data=$(curl \
  --silent \
  --location \
  https://packages.icinga.com/debian/dists/icinga-buster/main/binary-amd64/Packages)

echo -e "${data}" | \
  grep -E "^Package: icingaweb2" -A 7 | \
  grep "Version: " | \
  sort --version-sort | \
  tail -n 1 | \
  sed -e 's|Version: ||' -e 's|~||' -e 's|-1.buster||'
