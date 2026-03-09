#https://hub.docker.com/_/php
#https://gist.github.com/Tazeg/a49695c24b97ca879d4b6806a206981e

FROM php:8.5.3-apache-bookworm

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions imap gd mysqli zip exif sockets imap soap gmp gd opcache ldap

RUN pecl install xdebug;

RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
RUN a2enmod rewrite

COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

#install unzip for composer
RUN apt-get update && apt-get install -y unzip
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

RUN composer global require --dev "squizlabs/php_codesniffer=3.*"
RUN composer global require --dev "mockery/mockery"
