docker-icingaweb2
=================

Docker Container for icingaweb2 based on alpine-linux.

Now with PHP7 (7.x) Support and many installed modules and themes (see below).

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




# supported Environment Vars

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `MYSQL_HOST`                       | -                    | MySQL Host                                                      |
| `MYSQL_PORT`                       | `3306`               | MySQL Port                                                      |
| `MYSQL_ROOT_USER`                  | `root`               | MySQL root User                                                 |
| `MYSQL_ROOT_PASS`                  | -                    | MySQL root password                                             |
| `IDO_DATABASE_NAME`                | `icinga2core`        | Schema Name for IDO                                             |
| `IDU_USER`                         | `icinga2`            | IDO User                                                        |
| `IDO_PASSWORD`                     | -                    | IDO password                                                    |
| `IDO_COLLATION`                    | `latin1`             | IDO collate of DB                                               |
| `WEB_DATABASE_NAME`                | `icingaweb2`         | Name for the Icingaweb2 DB                                      |
| `WEB_DATABASE_USER`                | `icingaweb2`         | Username for the Icingaweb2 DB                                  |
| `WEB_DATABASE_PASS`                | `icingaweb2`         | Password for the Icingaweb2 DB                                  |
| `MYSQL_DIRECTOR_NAME`              | `director`           | Name for the Icinga Director DB                                 |
| `MYSQL_DIRECTOR_USER`              | `director`           | Username for the Icinga Director DB                             |
| `MYSQL_DIRECTOR_PASS`              | `director`           | Password for the Icinga Director DB                             |
| `REPORTING_DATABASE_NAME`          | `reporting`          | Name for the Icinga Reporting DB                                |
| `REPORTING_DATABASE_USER`          | `reporting`          | Username for the Icinga Reporting DB                            |
| `REPORTING_DATABASE_PASS`          | `reporting`          | Password for the Icinga Reporting DB                            |
| `VSPHEREDB_DATABASE_NAME`          | `vspheredb`          | Name for the Icinga Vsphere DB                                  |
| `VSPHEREDB_DATABASE_USER`          | `vspheredb`          | Username for the Icinga Vsphere DB                              |
| `REPORTING_DATABASE_PASS`          | `vspheredb`          | Password for the Icinga Vsphere DB                              |
| `X509_DATABASE_NAME`               | `x509`               | Name for the Icinga x509 DB                                     |
| `X509_DATABASE_USER`               | `x509`               | Username for the Icinga x509 DB                                 |
| `X509_DATABASE_PASS`               | `x509`               | Password for the Icinga x509 DB                                 |
|                                    |                      |                                                                 |
| `GRAPHITE_HOST`                    | -                    | Hostname for the graphite service<br>If no hostname is specified, the module is automatically deactivated.  |
| `GRAPHITE_HTTP_PORT`               | `8080`               | graphite port                                                   |
| `GRAPHITE_TIMERANGE`               | `6`                  | graphite default timerange in integer                           |
| `GRAPHITE_TIMERANGE_UNIT`          | `hours`              | graphite default timerange unit ("minutes,hours,days,weeks")    |
|                                    |                      |                                                                 |
| `ICINGA2_MASTER`                   | `icinga2-master`     | Icinga2 Host for Command Transport over API                     |
| `ICINGA2_MASTER2`                  | -                    | Icinga2 Master2,  activates HA Mode                             |
| `ICINGA2_API_PORT`                 | `5665`               | Icinga2 API Port                                                |
| `ICINGA2_CMD_API_USER`             | -                    | API User for Command Transport                                  |
| `ICINGA2_CMD_API_PASS`             | -                    | API Password for Command Transport                              |
| `ICINGA2_DIRECTOR_HOST`            | ${ICINGA2_MASTER}    | Override the DNS / IP for Director Kickstart, useful for local test |
|                                    |                      |                                                                 |
| `ICINGAWEB_ADMIN_USER`             | `icinga`             |                                                                 |
| `ICINGAWEB_ADMIN_PASS`             | `icinga`             |                                                                 |
| `ICINGAWEB2_USERS`                 | -                    | comma separated list to create Icingaweb2 Users. The format are `username:password`<br>(e.g. `admin:admin,dashing:dashing` and so on)      |
| `ICINGAWEB2_DEPLOYERS`             | -                    | comma separated list to create Icingaweb2 Deployers. The format are `username:password`<br>(e.g. `admin:admin,dashing:dashing` and so on)      |
|                                    |                      |                                                                 |
| `ICINGAWEB_DIRECTOR`               | `true`               | switch the Director configuration `on` / `off`<br>Disabling the Director automatically disables the following modules: *x509*, *vspheredb* |
| `ICINGA2_UPTIME`                   | `125`                | Waits (in seconds) for a stable running Icinga2 instance.<br>Otherwise the Director cannot be configured automatically.                    |

## Grafana Support

| Environmental Variable             | Default Value        | Description               |
| :--------------------------------- | :-------------       | :-----------              |
| `GRAFANA_HOST`                     | `grafana`            |                           |
| `GRAFANA_PORT`                     | `3000`               |                           |
| `GRAFANA_TIMERANGE`                | `12h`                |                           |
| `GRAFANA_TIMERANGE_ALL`            | `7d`                 |                           |
| `GRAFANA_DASHBOARD`                | `icinga2-default`    |                           |
| `GRAFANA_DASHBOARD_UID`            | ``                   |                           |
| `GRAFANA_PROTOCOL`                 | `http`               |                           |
| `GRAFANA_ACCESS`                   | `proxy`              |                           |
| `GRAFANA_AUTHENTICATION`           | `token`              |                           |
| `GRAFANA_AUTHENTICATION_TOKEN`     | ``                   |                           |
| `GRAFANA_AUTHENTICATION_USERNAME`  | `admin`              |                           |
| `GRAFANA_AUTHENTICATION_PASSWORD`  | `admin`              |                           |
| `GRAFANA_DATASOURCE`               | `influxdb`           |                           |
| `GRAFANA_ENABLE_LINK`              | `no`                 |                           |
| `GRAFANA_SHOW_DEBUG`               | `0`                  |                           |
| `GRAFANA_PUBLIC`                   | `no`                 |                           |
| `GRAFANA_PUBLIC_HOST`              | `localhost/grafana/` |                           |
| `GRAFANA_PUBLIC_PROTOCOL`          | `http`               |                           |
| `GRAFANA_THEME`                    | `light`              |                           |
| `GRAFANA_PROXY_TIMEOUT`            | `5`                  |                           |

## Module Support

Certain Icingaweb Modules can be disabled if not needed. By default most of them are enabled

| Environmental Variable     | Default Value    | Description                                       |
| :------------------------- | :-------------   | :-----------                                      |
| `ICINGAWEB_AWS`            | `true`           | https://github.com/Icinga/icingaweb2-module-aws   |
| `ICINGAWEB_BP`             | `true`           | https://github.com/Icinga/icingaweb2-module-businessprocess  |
| `ICINGAWEB_CUBE`           | `true`           | https://github.com/Icinga/icingaweb2-module-cube  |
| `ICINGAWEB_ES`             | `false`          | https://github.com/Icinga/icingaweb2-module-elasticsearch |
| `ICINGAWEB_FILESHIPPER`    | `false`          | https://github.com/Icinga/icingaweb2-module-fileshipper  |
| `ICINGAWEB_GLOBE`          | `true`           | https://github.com/Mikesch-mp/icingaweb2-module-globe  |
| `ICINGAWEB_IDOREPORTS`     | `true`           | https://github.com/Icinga/icingaweb2-module-idoreports does not work without reporting module  |
| `ICINGAWEB_MAP`            | `true`           | https://github.com/nbuchwitz/icingaweb2-module-map  |
| `ICINGAWEB_PDF`            | `false`          | https://github.com/Icinga/icingaweb2-module-pdfexport requires headless chrome! |
| `ICINGAWEB_REPORTING`      | `true`           | https://github.com/Icinga/icingaweb2-module-reporting  |
| `ICINGAWEB_TLV`            | `true`           | https://github.com/Icinga/icingaweb2-module-toplevelview  |
| `ICINGAWEB_VSPHEREDB`      | `true`           | https://github.com/Icinga/icingaweb2-module-vspheredb  |
| `ICINGAWEB_X509`           | `true`           | https://github.com/Icinga/icingaweb2-module-x509  |
| `ICINGAWEB_DIRECTOR`       | `true`           | switch the Director configuration `on` / `off`<br>Disabling the Director automatically disables the following modules: *x509*, *vspheredb* |


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
