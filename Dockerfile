# Use the official PHP image with Apache
FROM php:8.1-apache

# Install necessary system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath mbstring

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy the Laravel app to the /var/www/html directory
COPY . /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

#set composers memory limit
RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader


#clear cache
RUN composer clear-cache && composer install --no-dev --optimize-autoloader


# Set permissions (adjust as needed)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose the port
EXPOSE 80
