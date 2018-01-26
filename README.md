docker-icingaweb2
=================

Docker Container for icingaweb2 based on alpine-linux.

Now with PHP7 (7.1.12) Support and many installed modules (see below)

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-icingaweb2.svg?branch=1708-33)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-icingaweb2.svg?branch=1708-33)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-icingaweb2.svg?branch=1708-33)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-icingaweb2/
[microbadger]: https://microbadger.com/images/bodsch/docker-icingaweb2
[travis]: https://travis-ci.org/bodsch/docker-icingaweb2


# Build

Your can use the included Makefile.

- To build the Container: `make build`
- To remove the builded Docker Image: `make clean`
- Starts the Container: `make run`
- Starts the Container with Login Shell: `make shell`
- Entering the Container: `make exec`
- Stop (but **not kill**): `make stop`
- History `make history`

# Modules

 - [director](https://github.com/Icinga/icingaweb2-module-director)
 - [graphite](https://github.com/Icinga/icingaweb2-module-graphite)
 - [genericTTS](https://github.com/Icinga/icingaweb2-module-generictts)
 - [businessprocess](https://github.com/Icinga/icingaweb2-module-businessprocess)
 - [elasticsearch](https://github.com/Icinga/icingaweb2-module-elasticsearch)
 - [cube](https://github.com/Icinga/icingaweb2-module-cube)
 - [grafana](https://github.com/Mikesch-mp/icingaweb2-module-grafana)


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



## LDAP support

Please read more at the [official Icingaweb2 Doku](https://www.icinga.com/docs/icingaweb2/latest/doc/05-Authentication/#active-directory-or-ldap-authentication).

The environment variables for LDAP can be configured for 2 different reasons.:

### each environment variable is specified individually

- `LDAP_AD` (default: `false`) is the LDAP server an Active Directory
- `LDAP_SERVER` (default: `-`) the LDAP server
- `LDAP_PORT` (default:  `389`) the LDAP Port
- `LDAP_BIND_DN` (default:  `-`) LDAP Bind DN
- `LDAP_BIND_PASSWORD` (default:  `-`) Bind Password
- `LDAP_BASE_DN` (default:  `-`) Base DN
- `LDAP_FILTER` (default:  `-`) LDAP filter
- `LDAP_ROLE_GROUPS` (default:  `-`) LDAP groups
- `LDAP_ROLE_PERMISSIONS` (default:  `*`) LDAP group permissions

### an environment variable summarizes everything as json

- `LDAP`(default: `-`) json formated configuration

```json
{
  "active_directory": "true",
  "server":"${LDAP_SERVER}",
  "port":"${LDAP_PORT}",
  "bind_dn": "${LDAP_BIND_DN}",
  "bind_password": "${LDAP_BIND_PASSWORD}",
  "base_dn": "${LDAP_BASE_DN}",
  "filter": "${LDAP_FILTER}",
  "role": {
    "groups": "${LDAP_ROLE_GROUPS}",
    "permissions": "${LDAP_ROLE_PERMISSIONS}"
  }
}
```

