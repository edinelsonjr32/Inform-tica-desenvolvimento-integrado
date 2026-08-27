FROM php:8.4-cli

# Sistema
RUN apt-get update && apt-get install -y \
    git curl unzip wget jq libzip-dev libicu-dev libonig-dev \
    default-mysql-client redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Extensões PHP (incluindo redis!)
RUN docker-php-ext-install pdo pdo_mysql zip intl bcmath
RUN pecl install redis \
    && docker-php-ext-enable redis

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
