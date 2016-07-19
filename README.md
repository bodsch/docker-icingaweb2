docker-icingaweb2
=================

Docker Container for icingaweb2 based on alpine-linux.

# Status
[![Build Status](https://travis-ci.org/bodsch/docker-icingaweb2.svg?branch=master)](https://travis-ci.org/bodsch/docker-icingaweb2)

# Build

# Docker Hub

You can find the Container also at  [DockerHub](https://hub.docker.com/r/bodsch/docker-icingaweb2/)

# supported Environment Vars

for MySQL Support:

- ```MYSQL_HOST```
- ```MYSQL_PORT``` (default: ```3306```)
- ```MYSQL_ROOT_USER```
- ```MYSQL_ROOT_PASS```
- ```IDO_PASSWORD```
- ```IDO_DATABASE_NAME``` (default: ```icinga2```)

Authentication

- ```ICINGAWEB_ADMIN_USER``` (default: ```icinga```)
- ```ICINGAWEB_ADMIN_PASS``` (default: ```icinga```)

for Livestatus Support:

- ```LIVESTATUS_HOST``` (optional)
- ```LIVESTATUS_PORT``` (optional)


