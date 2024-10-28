# Use the official PHP 8.2 image with Apache
FROM php:8.2-apache

# Install necessary system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    unzip \
    git \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath mbstring \
    && apt-get clean

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory
WORKDIR /var/www/html

# Copy the Laravel application code into the container
COPY . .

# Set up permissions for storage and cache directories
RUN chown -R www-data:www-data storage bootstrap/cache

# Set up environment variables for Composer
ENV COMPOSER_MEMORY_LIMIT=-1

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --verbose

# Generate the .env file if it doesn't exist and set up the application key
RUN cp .env.example .env && php artisan key:generate --ansi

# Expose port 80 to serve the application
EXPOSE 80

# Start Laravel migrations (remove if handled externally)
RUN php artisan migrate --force

# Run Apache in the foreground
CMD ["apache2-foreground"]
