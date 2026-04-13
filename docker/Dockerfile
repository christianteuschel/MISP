FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV MISP_PATH=/var/www/MISP
ENV APACHE_USER=www-data

# System dependencies
RUN apt-get update && apt-get install -y \
    git curl zip gcc sudo binutils openssl gnupg2 \
    python3 python3-pip python3-virtualenv \
    apache2 \
    supervisor \
    mariadb-client \
    php8.3 php8.3-cli php8.3-dev \
    php8.3-xml php8.3-mysql php8.3-opcache php8.3-readline \
    php8.3-mbstring php8.3-zip php8.3-intl php8.3-bcmath \
    php8.3-gd php8.3-redis php8.3-gnupg php8.3-apcu \
    libapache2-mod-php8.3 php8.3-curl \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Configure PHP for Apache
RUN PHP_INI=/etc/php/8.3/apache2/php.ini && \
    sed -i "s/^\(upload_max_filesize\).*/\1 = 50M/"  "$PHP_INI" && \
    sed -i "s/^\(post_max_size\).*/\1 = 50M/"        "$PHP_INI" && \
    sed -i "s/^\(max_execution_time\).*/\1 = 300/"   "$PHP_INI" && \
    sed -i "s/^\(max_input_time\).*/\1 = 300/"       "$PHP_INI" && \
    sed -i "s/^\(memory_limit\).*/\1 = 2048M/"       "$PHP_INI" && \
    sed -i "s/^\(session.sid_length\).*/\1 = 32/"    "$PHP_INI" && \
    sed -i "s/^\(session.use_strict_mode\).*/\1 = 1/" "$PHP_INI"

# Configure PHP CLI (for cake console)
RUN PHP_CLI_INI=/etc/php/8.3/cli/php.ini && \
    sed -i "s/^\(max_execution_time\).*/\1 = 0/"   "$PHP_CLI_INI" && \
    sed -i "s/^\(memory_limit\).*/\1 = 2048M/"     "$PHP_CLI_INI"

# Enable Apache modules and site
RUN a2enmod rewrite headers
COPY docker/apache-misp.conf /etc/apache2/sites-available/misp.conf
RUN a2ensite misp && a2dissite 000-default

# Create MISP directory (source will be mounted over it)
RUN mkdir -p "$MISP_PATH" && \
    mkdir -p /var/www/.cache && \
    chown -R "${APACHE_USER}:${APACHE_USER}" /var/www/.cache

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
