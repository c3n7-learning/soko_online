# https://github.com/docker-library/php/issues/797
ARG PHP_EXTS="pdo pdo_mysql pcntl zip gd gmp"
ARG PHP_EXT_HOSTS="zip libzip-dev freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev gmp-dev mysql mysql-client mariadb-connector-c"

# ========================================
# Install extensions
# ========================================
FROM composer:lts as build
COPY . /app/
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs


# ========================================
# Build Frontend
# ========================================
# For the frontend, we want to get all the Laravel files,
# and run a production compile
FROM node:20-alpine as frontend

# We need to copy in the Laravel files to make everything is available to our frontend compilation
COPY --from=build /app /app

WORKDIR /app

RUN apk update && apk add git

# We want to install all the NPM packages,
# and compile theproduction build
RUN npm install && \
    npm run build

# ========================================
# For php artisan cli etc
# ========================================
FROM php:8.2-cli-alpine as cli

ARG PHP_EXTS
ARG PHP_EXT_HOSTS

WORKDIR /opt/apps/www

RUN apk update && apk add ${PHP_EXT_HOSTS} && \
    docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype && \
    docker-php-ext-install ${PHP_EXTS}


COPY --from=build --chown=www-data:www-data /app /opt/apps/www



# ========================================
# FPM server to process requests
# ========================================
FROM php:8.2-fpm-alpine as fpm_server

ARG PHP_EXTS
ARG PHP_EXT_HOSTS

WORKDIR /opt/apps/www

RUN apk update && apk add ${PHP_EXT_HOSTS} && \
    docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype && \
    docker-php-ext-install ${PHP_EXTS}

# As FPM uses the www-data user when running our application,
# we need to make sure that we also use that user when starting up,
# so our user "owns" the application when running
USER www-data

COPY devops/docker/php/conf.d/php.ini /usr/local/etc/php/conf.d/php.ini
COPY devops/docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY --from=build --chown=www-data:www-data /app /opt/apps/www

RUN mkdir -p /opt/apps/www/storage/logs && \
    chmod -R 777 /opt/apps/www/storage



# ========================================
# NGINX container
# ========================================
FROM nginx:1.25-alpine as nginx_server
WORKDIR /opt/apps/www


# We need to add our NGINX template to the container for startup,
# and configuration.
COPY devops/docker/nginx.conf.template /etc/nginx/templates/default.conf.template

# Copy in ONLY the public directory of our project.
# This is where all the static assets will live, which nginx will serve for us.
COPY --from=build /app/public /opt/apps/www/public
COPY --from=frontend /app/public/build /opt/apps/www/public/build
