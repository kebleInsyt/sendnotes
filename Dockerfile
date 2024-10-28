# Use the official PHP image with Apache
FROM php:8.1-apache


# Install necessary packages including PostgreSQL development libraries
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql


# Copy the Laravel app to the /var/www/html directory
COPY . /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install app dependencies
RUN composer install --no-dev --optimize-autoloader

# Set permissions (adjust as needed)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose the port
EXPOSE 80
