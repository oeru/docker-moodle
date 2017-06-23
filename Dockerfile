FROM php:7.0-fpm
MAINTAINER Dave Lane <dave@oerfoundation.org> (@lightweight)
# based on that by MAINTAINER Michael Babker <michael.babker@moodle.org> (@mbabker)

# Install PHP extensions
RUN apt-get update && apt-get install -y apt-utils git libc-client-dev libcurl4-gnutls-dev \
    libicu-dev libkrb5-dev libmcrypt-dev libpng-dev libssl-dev
RUN apt-get install -y net-tools vim dnsutils
# install cron and msmtp for outgoing email
RUN apt-get install -y cron msmtp
# clean up
RUN rm -rf /var/lib/apt/lists/*
# install relevant PHP extensions
RUN docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos
RUN docker-php-ext-install curl gd imap intl mbstring mcrypt mysqli mysqlnd pdo pdo_mysql pspell xmlrpc
# address Moodle-specific PHP config requirements
RUN echo "always_populate_raw_post_data = -1;" > /usr/local/etc/php/conf.d/php.ini
RUN echo 'date.timezone = "Pacific/Auckland";' >> /usr/local/etc/php/conf.d/php.ini
RUN echo 'cgi.fix_pathinfo = 0;' >> /usr/local/etc/php/conf.d/php.ini
# set up cron task
RUN echo '# cron job for Moodle - dave@oerfoundation.org' > /etc/cron.d/moodle-cron
RUN echo '# Run every 10 minutes' >> /etc/cron.d/moodle-cron
RUN echo '*/10 * * * * root php -q -f /var/www/html/moodle/admin/cli/cron.php' >> /etc/cron.d/moodle-cron

VOLUME /var/www/html

# Define Moodle version and expected SHA1 signature
ENV MOODLE_VERSION moodle-latest-33

# do a GitHub download
# Download package and extract to web volume
RUN curl -o moodle.tgz -SL https://download.moodle.org/download.php/direct/stable33/${MOODLE_VERSION}.tgz \
	&& tar xfz moodle.tgz -d /usr/src \
    && mv /usr/src/${MOODLE_VERSION} /usr/src/moodle \
	&& rm moodle.tgz \
	&& chown -R www-data:www-data /usr/src/moodle

# Copy configuration scripts to the container
COPY docker-entrypoint.sh /entrypoint.sh
COPY makeconfig.php /makeconfig.php
COPY makedb.php /makedb.php
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
