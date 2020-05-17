[global]
daemonize = no
error_log = /proc/self/fd/2
pid       = /run/php-fpm.pid
include   = /etc/php/${PHP_VERSION}/fpm/pool.d/*.conf