FROM php:7.0-fpm
MAINTAINER Dave Lane <dave@oerfoundation.org> (@lightweight)
# based on that by MAINTAINER Michael Babker <michael.babker@moodle.org> (@mbabker)

# Install PHP extensions
RUN apt-get update && apt-get install -y apt-utils git less libbz2-dev libc-client-dev \
    libcurl4-gnutls-dev libicu-dev libkrb5-dev libmcrypt-dev libpng-dev \
    libpspell-dev libssl-dev libxml2-dev telnet unzip zip
RUN apt-get install -y net-tools vim dnsutils
# install cron and msmtp for outgoing email
RUN apt-get install -y cron msmtp
# clean up
RUN rm -rf /var/lib/apt/lists/*
# install relevant PHP extensions
RUN docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos
RUN docker-php-ext-install bz2 curl gd imap intl mbstring mcrypt mysqli \
    opcache pdo pdo_mysql pspell soap xmlrpc zip
# address Moodle-specific PHP config requirements
# php.ini
RUN set -ex \
    && { \
        echo 'log_errors = on'; \
        echo 'display_errors = off'; \
        echo 'always_populate_raw_post_data = -1'; \
        echo 'date.timezone = "Pacific/Auckland"'; \
        echo 'cgi.fix_pathinfo = 1'; \
        echo 'session.auto_start = 0'; \
        echo 'sendmail_path = /usr/bin/msmtp -t'; \
        echo 'upload_max_filesize = 100M'; \
        echo 'post_max_size = 150M'; \
        echo 'max_execution_time = 1800'; \
        echo '[opcache]'; \
        echo 'opcache.enable = 1'; \
        echo 'opcache.memory_consumption = 128'; \
        echo 'opcache.max_accelerated_files = 8000'; \
        echo 'opcache.revalidate_freq = 60'; \
        echo 'opcache.use_cwd = 1'; \
        echo 'opcache.validate_timestamps = 1'; \
        echo 'opcache.save_comments = 1'; \
        echo 'opcache.enable_file_override = 0'; \ 
    } | tee /usr/local/etc/php/conf.d/php.ini
# the PHP-fpm configuration
RUN set -ex \
    && { \
        echo '[global]'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo '[www]'; \
        echo 'user = www-data'; \
        echo 'group = www-data'; \
        echo '; if we send this to /proc/self/fd/1, it never appears'; \
        echo 'access.log = /proc/self/fd/2'; \
        echo 'clear_env = no'; \
        echo 'request_terminate_timeout = 1800'; \
        echo 'catch_workers_output = yes'; \
        echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
        echo 'pm = ondemand'; \
        echo 'pm.max_children = 20'; \
        echo 'pm.start_servers = 2'; \
        echo 'pm.min_spare_servers = 1'; \
        echo 'pm.max_spare_servers = 3'; \
        echo 'php_flag[display_errors] = off'; \
        echo 'php_admin_value[error_log] = /var/log/fpm-php.www.log'; \
        echo 'php_admin_flag[log_errors] = on'; \
        echo 'php_admin_value[memory_limit] = 200M'; \
        echo 'security.limit_extensions = .php'; \
    } | tee /usr/local/etc/php-fpm.d/www.conf


VOLUME ['/var/www/html']

# Define Moodle version
#ENV MOODLE_VERSION moodle-34
#
# instead install this via https://docs.moodle.org/34/en/Git_for_Administrators#Obtaining_the_code_from_Git


# do a GitHub download
# Download package and extract to web volume
#RUN curl -o moodle.tgz -SL https://download.moodle.org/download.php/direct/stable34/moodle-latest-34.tgz \
#	&& tar xfz moodle.tgz -C /usr/src \
#    && rm moodle.tgz \
#	&& chown -R www-data:www-data /usr/src/moodle

# Copy configuration scripts to the container
COPY conf/msmtp/msmtprc /etc/msmtprc
RUN chgrp mail /etc/msmtprc


COPY docker-entrypoint.sh /entrypoint.sh
COPY makeconfig.php /makeconfig.php
COPY makedb.php /makedb.php
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
