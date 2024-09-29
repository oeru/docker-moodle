FROM oeru/moodle:php81-fpm
MAINTAINER Dave Lane <dave@oerfoundation.org> https://oeru.org (@lightweight)

# set up vital cron tasks
RUN set -ex \
    && { \
        echo '# cron jobs for Moodle - dave@oerfoundation.org'; \
        echo 'PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'; \
        echo 'OUT=/var/log/cron.log'; \
        echo '# cron job for Moodle - dave@oerfoundation.org'; \
        echo '# Run every minute'; \
        echo '*/1 * * * * root php -q -f /var/www/html/admin/cli/cron.php >> $OUT'; \
    } | tee /etc/cron.d/moodle-cron
RUN chmod a+x /etc/cron.d/moodle-cron
RUN touch 0644 /var/log/cron.log
VOLUME ['/var/www/html']

CMD cron && tail -f /var/log/cron.log


