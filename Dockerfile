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

# Set the working directory to /var/www/html (where Apache serves files)
WORKDIR /var/www/html

# Copy the Laravel application code into the container
COPY . .

# Change Apache DocumentRoot to Laravel's public directory
RUN sed -i 's|/var/www/html|/var/www/html/public|' /etc/apache2/sites-available/000-default.conf

# Enable Apache rewrite module for Laravel routing
RUN a2enmod rewrite

# Set up permissions for storage and cache directories
RUN chown -R www-data:www-data storage bootstrap/cache

# Set up environment variables for Composer
ENV COMPOSER_MEMORY_LIMIT=-1

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --verbose

# Generate the .env file if it doesn't exist and set up the application key
RUN cp .env.example .env && php artisan key:generate --ansi

# Set ServerName to suppress warnings
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set permissions for Laravel storage and cache
RUN chmod -R 775 storage bootstrap/cache && chown -R www-data:www-data storage bootstrap/cache


# Expose port 80 to serve the application
EXPOSE 80

# Start Laravel migrations (remove if handled externally)
RUN php artisan migrate --force

# Run Apache in the foreground
CMD ["apache2-foreground"]
