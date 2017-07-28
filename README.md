docker-icingaweb2
=================

Docker Container for icingaweb2 based on alpine-linux.

Now with PHP7 Support and many installed modules (see below)

Integrates also the grafana Modue from [Mikesch-mp](https://github.com/Mikesch-mp/icingaweb2-module-grafana.git)

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-icingaweb2.svg?branch=1707-30)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-icingaweb2.svg?branch=1707-30)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-icingaweb2.svg?branch=1707-30)][travis]

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

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `MYSQL_HOST`                       | -                    | MySQL Host                                                      |
| `MYSQL_PORT`                       | `3306`               | MySQL Port                                                      |
| `MYSQL_ROOT_USER`                  | `root`               | MySQL root User                                                 |
| `MYSQL_ROOT_PASS`                  | -                    | MySQL root password                                             |
| `IDO_DATABASE_NAME`                | `icinga2core`        | Schema Name for IDO                                             |
| `IDO_PASSWORD`                     | -                    | IDO password                                                    |
|                                    |                      |                                                                 |
| `GRAPHITE_HOST`                    | -                    |                                                                 |
| `GRAPHITE_PORT`                    | `2003`               |                                                                 |
|                                    |                      |                                                                 |
| `ICINGA2_HOST`                     | `icinga2-master`     | Icinga2 Host for Command Transport over API                     |
| `ICINGA2_PORT`                     | `5665`               | Icinga2 API Port                                                |
| `ICINGA2_CMD_API_USER`             | -                    | API User for Command Transport                                  |
| `ICINGA2_CMD_API_PASS`             | -                    | API Password for Command Transport                              |
|                                    |                      |                                                                 |
| `ICINGAWEB_ADMIN_USER`             | `icinga`             |                                                                 |
| `ICINGAWEB_ADMIN_PASS`             | `icinga`             |                                                                 |
| `ICINGAWEB2_USERS`                 | -                    | comma separated List to create Icingaweb2 Users. The Format are `username:password` |
|                                    |                      | (e.g. `admin:admin,dashing:dashing` and so on)                  |
|                                    |                      |                                                                 |
