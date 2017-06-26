#!/bin/bash

set -e

if [ -n "$MYSQL_PORT_3306_TCP" ]; then
    if [ -z "$MOODLE_DB_HOST" ]; then
            MOODLE_DB_HOST='mysql'
    else
        echo >&2 "warning: both MOODLE_DB_HOST and MYSQL_PORT_3306_TCP found"
        echo >&2 "  Connecting to MOODLE_DB_HOST ($MOODLE_DB_HOST)"
        echo >&2 "  instead of the linked mysql container"
    fi
fi

if [ -z "$MOODLE_DB_HOST" ]; then
    echo >&2 "error: missing MOODLE_DB_HOST and MYSQL_PORT_3306_TCP environment variables"
    echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
    echo >&2 "  with -e MOODLE_DB_HOST=hostname:port?"
    exit 1
fi

# If the DB user is 'root' then use the MySQL root password env var
: ${MOODLE_DB_USER:=root}
if [ "$MOODLE_DB_USER" = 'root' ]; then
    : ${MOODLE_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${MOODLE_DB_NAME:=moodle}

if [ -z "$MOODLE_DB_PASSWORD" ]; then
    echo >&2 "error: missing required MOODLE_DB_PASSWORD environment variable"
    echo >&2 "  Did you forget to -e MOODLE_DB_PASSWORD=... ?"
    echo >&2
    echo >&2 "  (Also of interest might be MOODLE_DB_USER and MOODLE_DB_NAME.)"
    exit 1
fi

if ! [ -e index.php -a -e admin/cli/cron.php ]; then
    echo >&2 "Moodle not found in $(pwd) - copying now..."

    if [ "$(ls -A)" ]; then
        echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
        ( set -x; ls -A; sleep 10 )
    fi

    tar cf - --one-file-system -C /usr/src/moodle . | tar xf -

    echo >&2 "Complete! Moodle has been successfully copied to $(pwd)"
fi

# run composer to set up dependencies if not already there...
if ! [ -e vendor/autoload.php ]; then
    echo >&2 "installing dependencies with Composer"
    if ! [ -e /usr/local/bin/composer ]; then
        echo >&2 "first getting Composer"
        # Get Composer
        curl -S https://getcomposer.org/installer | php
        chmod a+x composer.phar
        mv composer.phar /usr/local/bin/composer
    fi
    if ! [ -e .git/hooks ]; then
        echo >&2 "creating a .git/hooks dir to avoid errors"
        mkdir -p .git/hooks
    fi
    composer install
else
    echo >&2 "vendor dependencies already in place."
fi

# Ensure the MySQL Database is created
php /makedb.php "$MOODLE_DB_HOST" "$MOODLE_DB_USER" "$MOODLE_DB_PASSWORD" "$MOODLE_DB_NAME"

echo >&2 "========================================================================"
echo >&2
echo >&2 "This server is now configured to run Moodle!"
echo >&2 "You will need the following database information to install Moodle:"
echo >&2 "Domain: $MOODLE_DOMAIN"
echo >&2 "Host Name: $MOODLE_DB_HOST"
echo >&2 "Database Name: $MOODLE_DB_NAME"
echo >&2 "Database Username: $MOODLE_DB_USER"
echo >&2 "Database Password: $MOODLE_DB_PASSWORD"
echo >&2
echo >&2 "========================================================================"

# Write the database connection to the config so the installer prefills it
if ! [ -e config.php ]; then
    php /makeconfig.php "$MOODLE_DOMAIN" "$MOODLE_DB_HOST" "$MOODLE_DB_USER" "$MOODLE_DB_PASSWORD" "$MOODLE_DB_NAME"

    # Make sure our web user owns the config file if it exists
    chown www-data:www-data config.php
fi

exec "$@"
