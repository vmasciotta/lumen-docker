FROM php:7.2-apache

MAINTAINER Valerio Masciotta <sviluppo@valeriomasciotta.it>

ENV XDEBUG_PORT 9000

# Install System Dependencies

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	software-properties-common \
	#python-software-properties \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	libfreetype6-dev \
	libicu-dev \
  	libssl-dev \
	libjpeg62-turbo-dev \
	libmcrypt-dev \
	libpng-dev \
	libedit-dev \
	libedit2 \
	libxslt1-dev \
	apt-utils \
  	mysql-client \
	git \
	vim \
	wget \
	curl \
	lynx \
	psmisc \
	unzip \
	tar \
	cron \
    openssl \
    nano \
	bash-completion \
	&& apt-get clean

# Install PHP Dependencies

RUN docker-php-ext-configure \
  	gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
  	docker-php-ext-install \
  	opcache \
  	gd \
  	bcmath \
  	intl \
  	mbstring \
  	pdo_mysql \
  	soap \
  	xsl \
  	zip

# Install oAuth

RUN apt-get update \
  	&& apt-get install -y \
  	libpcre3 \
  	libpcre3-dev \
  	# php-pear \
  	&& pecl install oauth \
  	&& echo "extension=oauth.so" > /usr/local/etc/php/conf.d/docker-php-ext-oauth.ini

# Install Composer

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install Mhsendmail

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install golang-go \
   && mkdir /opt/go \
   && export GOPATH=/opt/go \
   && go get github.com/mailhog/mhsendmail

# Install XDebug

RUN yes | pecl install xdebug && \
	 echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.iniOLD


# Configuring system

ADD .docker/config/php.ini /usr/local/etc/php/php.ini
ADD .docker/config/lumen.conf /etc/apache2/sites-available/000-default.conf
ADD .docker/config/lumen.conf /etc/apache2/sites-available/001-lumen.conf
ADD .docker/config/custom-xdebug.ini /usr/local/etc/php/conf.d/custom-xdebug.ini
COPY .docker/bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*
RUN ln -s /etc/apache2/sites-available/001-lumen.conf /etc/apache2/sites-enabled/001-lumen.conf

RUN chmod 777 -Rf /var/www /var/www/.* \
	&& chown -Rf www-data:www-data /var/www /var/www/.* \
	&& usermod -u 1000 www-data \
	&& chsh -s /bin/bash www-data\
	&& a2enmod rewrite \
	&& a2enmod headers

VOLUME /var/www/html
WORKDIR /var/www/html
