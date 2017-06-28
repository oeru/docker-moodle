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
RUN echo "always_populate_raw_post_data = -1" > /usr/local/etc/php/conf.d/php.ini
RUN echo 'date.timezone = "Pacific/Auckland"' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'cgi.fix_pathinfo = 1' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'session.auto_start = 0' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'sendmail_path = /usr/bin/msmtp -t' >> /usr/local/etc/php/conf.d/php.ini
RUN echo '[opcache]' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.enable = 1' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.memory_consumption = 128' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.max_accelerated_files = 8000' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.revalidate_freq = 60' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.use_cwd = 1' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.validate_timestamps = 1' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.save_comments = 1' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'opcache.enable_file_override = 0' >> /usr/local/etc/php/conf.d/php.ini
# the PHP-fpm configuration
RUN echo 'php_flag[display_errors] = off' >> /usr/local/etc/php-fpm.d/www.conf
RUN echo 'php_admin_value[error_log] = /var/log/fpm-php.www.log' >> /usr/local/etc/php-fpm.d/www.conf
RUN echo 'php_admin_flag[log_errors] = on' >> /usr/local/etc/php-fpm.d/www.conf
RUN echo 'php_admin_value[memory_limit] = 120M' >> /usr/local/etc/php-fpm.d/www.conf
RUN echo 'security.limit_extensions = .php' >> /usr/local/etc/php-fpm.d/www.conf


# set up cron task
RUN echo '# cron job for Moodle - dave@oerfoundation.org' > /etc/cron.d/moodle-cron
RUN echo '# Run every 10 minutes' >> /etc/cron.d/moodle-cron
RUN echo '*/10 * * * * root php -q -f /var/www/html/moodle/admin/cli/cron.php' >> /etc/cron.d/moodle-cron

VOLUME /var/www/html

# Define Moodle version
ENV MOODLE_VERSION moodle-latest-33

# do a GitHub download
# Download package and extract to web volume
RUN curl -o moodle.tgz -SL https://download.moodle.org/download.php/direct/stable33/moodle-latest-33.tgz \
	&& tar xfz moodle.tgz -C /usr/src \
  && rm moodle.tgz \
	&& chown -R www-data:www-data /usr/src/moodle

# Copy configuration scripts to the container
COPY conf/msmtp/msmtprc /etc/msmtprc
RUN chgrp mail /etc/msmtprc


COPY docker-entrypoint.sh /entrypoint.sh
COPY makeconfig.php /makeconfig.php
COPY makedb.php /makedb.php
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
