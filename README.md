Docker Moodle Image
===================
# License

Moodle (and this Docker Recipe) is distributed under the GPL v3 license. Full details of the license can be found in the [Moodle Docs](https://docs.moodle.org/dev/License).


# Latest images:

20230501:

oeru/moodle:php80-fpm
oeru/moodle-cron:php80-fpm


# How to use this image

These instructions might be useful to some, so I'm leaving them here, but I've written more comprehensive instructions on https://tech.oeru.org/installing-moodle-php7-fpm-docker-nginx-and-mariadb-ubuntu-1604

1. you need a Docker host configured to use both a current Docker and Docker Compose with network access and git installed.  

1. make sure you have a MySQL or MariaDB running either on your Docker host, or in a container

1. clone this repo:
`git clone git@github.com:oeru/docker-moodle.git`
which will, by default, create a directory called 'docker-moodle'

1. create a local docker-compose.yml by copying docker-compose.yml-sample:
`cd docker-moodle`
`cp docker-compose.yml-sample docker-compose.yml`
and the edit the file to specify the details of your MySQL or MariaDB database. You need to specify a user who has the ability to create a database. Also, if you're running an nginx container, you can tweak the ports assignments to make it publicly visible (I encourage defaulting to SSL!).

1. adjust the nginx "default.conf" (replace it with "ssl.conf" if you want to offer secure hosting!) and set up the path to your repo in the yml file so that the nginx container can find the conf file.

1. you also need to create a directory on your Docker host for your Moodle code, and reference it in the yml file.

1. then run
`docker-compose up`
to pull (if necessary) and run your moodle (and, if you're using it) your nginx container. If you're running it locally, access it via `http://localhost:8083` in a browser.

1. Run `docker-compose up`, wait for it to initialize completely, and visit `http://localhost:8080` or `http://host-ip:8080`.

# Running a MySQL/MariaDB container...

If you're running MySQL or MariaDB in another container, add another stanza to this yml file to describe it and link it with the moodle stanza!

    moodle:
	  image: oeru/moodle
	  links:
	    - moodledb:mysql
	  ports:
	    - ...
    moodledb:
	  image: mariadb

# Supported Docker versions

This has been tested on Docker 1.13.1 on Ubuntu Linux 16.04 and requires Docker 1.10.x or better.

# Notes

1. need to configure local MySQL or MariaDB to bind to 0.0.0.0 rather than 127.0.0.1

1. need to make configuration changes to DB - for mariadb, edit `/etc/mysql/mariadb.conf.d/50-server.cnf` and add under `[mysqld] the following lines:


  innodb_file_format = Barracuda
  innodb_file_per_table = 1
  innodb_large_prefix
  character-set-server = utf8mb4
  collation-server = utf8mb4_unicode_ci
  skip-character-set-client-handshake

1. if you're using SSL (like Let's Encrypt) make sure that your moodle/src/config.php includes the line 

  $CFG->sslproxy=true;


# User Feedback

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/oeru/docker-moodle/issues). We will endeavour to assist, although we're doing this through enlightened self-interest, so can't provide any guarantees!
