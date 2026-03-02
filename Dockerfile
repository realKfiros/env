#https://hub.docker.com/_/php
#https://gist.github.com/Tazeg/a49695c24b97ca879d4b6806a206981e

FROM php:8.5-apache-bookworm

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update

#https://github.com/mlocati/docker-php-extension-installer/blob/master/install-php-extensions
RUN apt-get install -y libzip-dev libkrb5-dev libc-client2007e-dev libxml2-dev libgmp-dev zlib1g-dev libpng-dev libjpeg62-turbo-dev git
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-configure gd --with-jpeg
RUN docker-php-ext-install mysqli zip exif sockets imap soap gmp gd opcache #ldap
RUN docker-php-ext-install pdo_mysql #required only for this test project

RUN pecl install xdebug;

RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
RUN a2enmod rewrite

COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

#install unzip for composer
RUN apt-get install -y unzip
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# Install Node.js (using NodeSource repository for latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

# Install Playwright dependencies and browsers
RUN npx -y playwright@1.55.1 install --with-deps

RUN composer global require --dev "squizlabs/php_codesniffer=3.*"
RUN composer global require --dev "mockery/mockery"
