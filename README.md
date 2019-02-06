docker-icingaweb2
=================

Docker Container for icingaweb2 based on alpine-linux.

Now with PHP7 (7.x) Support and many installed modules and themes (see below).

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-icingaweb2.svg)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-icingaweb2.svg)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-icingaweb2.svg)][travis]

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


# director integration in combination with a dockerized icinga2-master

The Director will be automated configured.
For this we need a stable running Icinga2 master.

For this we check the availability of the API port (5665) and wait until the Icinga2 master has reached an uptime of 2 minutes.


# Modules

- [director](https://github.com/Icinga/icingaweb2-module-director)
- [graphite](https://github.com/Icinga/icingaweb2-module-graphite)
- [genericTTS](https://github.com/Icinga/icingaweb2-module-generictts)
- [businessprocess](https://github.com/Icinga/icingaweb2-module-businessprocess)
- [elasticsearch](https://github.com/Icinga/icingaweb2-module-elasticsearch)
- [cube](https://github.com/Icinga/icingaweb2-module-cube)
- [aws](https://github.com/Icinga/icingaweb2-module-aws)
- [fileshipper](https://github.com/Icinga/icingaweb2-module-fileshipper)
- [grafana](https://github.com/Mikesch-mp/icingaweb2-module-grafana)
- [globe](https://github.com/Mikesch-mp/icingaweb2-module-globe)
- [map](https://github.com/nbuchwitz/icingaweb2-module-map)
- [boxydash](https://github.com/morgajel/icingaweb2-module-boxydash)
- [toplevelview](https://github.com/Icinga/icingaweb2-module-toplevelview)
- [vspheredb](https://github.com/Thomas-Gelf/icingaweb2-module-vspheredb)
- [x509](https://github.com/Icinga/icingaweb2-module-x509d)



## vspheredb

The implementation of the plugin used here does not use the integrated daemon, because it is
currently causing problems.<br>
Instead, the commandline tools are integrated via a separate process.

### known bus / problems

After deleting a vcenter, fragments of VMs, datastores, etc. remain in the database and can still be displayed.

## x509

You can add an customized configuration for the `x509` module by adding an directory `/init/custom.d/x509` and drop a `jobs.ini` file:

Example file
```bash
[google]
cidrs = "172.217.21.227/32"
ports = "443"
schedule = "0 0 * * *"
```
For more information read the module [documentation](https://github.com/Icinga/icingaweb2-module-x509/blob/master/doc/03-Configuration.md)!


# Themes

 - [unicorn](https://github.com/Mikesch-mp/icingaweb2-theme-unicorn)
 - [lsd](https://github.com/Mikesch-mp/icingaweb2-theme-lsd)
 - [april](https://github.com/Mikesch-mp/icingaweb2-theme-april)
 - [company](https://github.com/Icinga/icingaweb2-theme-company)
 - [batman](https://github.com/jschanz/icingaweb2-theme-batman)
 - [batman-dark](https://github.com/jschanz/icingaweb2-theme-batman-dark)
 - [nordlicht](https://github.com/sysadmama/icingaweb2-theme-nordlicht)
 - [spring](https://github.com/dnsmichi/icingaweb2-theme-spring)
 - [dark](https://github.com/vita2/icingaweb2-module-theme-dark)
 - [beyondthepines](https://github.com/Wintermute2k6/icingaweb2-module-beyondthepines)
 - [always-green](https://github.com/xam-stephan/icingaweb2-module-theme-always-green)
 - [colourblind](https://github.com/sol1/icingaweb2-theme-colourblind)
 - [particles](https://github.com/Mikesch-mp/icingaweb2-theme-particles)


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
| `GRAPHITE_HOST`                    | -                    | Hostname for the graphite service<br>If no hostname is specified, the module is automatically deactivated.                                                                |
| `GRAPHITE_HTTP_PORT`               | `8080`               | graphite port                                                   |
|                                    |                      |                                                                 |
| `ICINGA2_MASTER`                   | `icinga2-master`     | Icinga2 Host for Command Transport over API                     |
| `ICINGA2_API_PORT`                 | `5665`               | Icinga2 API Port                                                |
| `ICINGA2_CMD_API_USER`             | -                    | API User for Command Transport                                  |
| `ICINGA2_CMD_API_PASS`             | -                    | API Password for Command Transport                              |
|                                    |                      |                                                                 |
| `ICINGAWEB_ADMIN_USER`             | `icinga`             |                                                                 |
| `ICINGAWEB_ADMIN_PASS`             | `icinga`             |                                                                 |
| `ICINGAWEB2_USERS`                 | -                    | comma separated list to create Icingaweb2 Users. The format are `username:password`<br>(e.g. `admin:admin,dashing:dashing` and so on)      |
|                                    |                      |                                                                 |
| `ICINGAWEB_DIRECTOR`               | `true`               | switch the Director configuration `on` / `off`<br>Disabling the Director automatically disables the following modules: *x509*, *vspheredb* |
| `ICINGA2_UPTIME`                   | `125`                | Waits (in seconds) for a stable running Icinga2 instance.<br>Otherwise the Director cannot be configured automatically.                    |




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

