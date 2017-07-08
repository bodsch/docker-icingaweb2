docker-icingaweb2
=================

Docker Container for icingaweb2 based on alpine-linux.

Now with PHP7 Support and many installed modules (see below)

Integrates also the grafana Modue from [Mikesch-mp](https://github.com/Mikesch-mp/icingaweb2-module-grafana.git)

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-icingaweb2.svg?branch=1705-01)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-icingaweb2.svg?branch=1705-01)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-icingaweb2.svg?branch=1705-01)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-icingaweb2/
[microbadger]: https://microbadger.com/images/bodsch/docker-icingaweb2
[travis]: https://travis-ci.org/bodsch/docker-icingaweb2


# Build

Your can use the included Makefile.

To build the Container: `make build`

To remove the builded Docker Image: `make clean`

Starts the Container: `make run`

Starts the Container with Login Shell: `make shell`

Entering the Container: `make exec`

Stop (but **not kill**): `make stop`

History `make history`

Starts a *docker-compose*: `make compose-up`

Remove the *docker-compose* images: `make compose-down`


# Modules

 - director
 - graphite
 - genericTTS
 - businessprocess
 - elasticsearch
 - cube
 - grafana


# Docker Hub

You can find the Container also at  [DockerHub](https://hub.docker.com/r/bodsch/docker-icingaweb2/)

# supported Environment Vars

for MySQL Support:

- `MYSQL_HOST`
- `MYSQL_PORT` (default: `3306`)
- `MYSQL_ROOT_USER`
- `MYSQL_ROOT_PASS`
- `IDO_PASSWORD`
- `IDO_DATABASE_NAME` (default: `icinga2`)

Graphite Support:

- `GRAPHITE_HOST`
- `GRAPHITE_PORT`

Command Transport (now over API)

- `ICINGA2_HOST` (default: `icinga2-master`
- `ICINGA2_PORT` (default: `5665`

- `ICINGA2_CMD_API_USER`
- `ICINGA2_CMD_API_PASS`


Authentication

- `ICINGAWEB_ADMIN_USER` (default: `icinga`)
- `ICINGAWEB_ADMIN_PASS` (default: `icinga`)

