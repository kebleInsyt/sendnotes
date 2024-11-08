# Use the official PHP 8.2 image with Apache
FROM php:8.2-apache

# Install necessary system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    unzip \
    git \
    curl \
    npm \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath mbstring \
    && apt-get clean

# Install Node.js 18.x (or your preferred version)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory
WORKDIR /var/www/html

# Copy composer files first
COPY composer.json composer.lock ./

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install npm dependencies
RUN npm clean-install

# Copy the rest of the application
COPY . .

# Set up environment file
RUN cp .env.example .env
RUN php artisan key:generate --ansi

# Build assets with npm
RUN npm run build

# Verify the manifest file exists
RUN test -f public/build/manifest.json || exit 1

# Configure Apache
RUN sed -i 's|/var/www/html|/var/www/html/public|' /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set proper permissions
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache
RUN chown -R www-data:www-data public/build

# Expose port 80
EXPOSE 80

# Start Apache and run migrations
CMD ["sh", "-c", "php artisan migrate --force && apache2-foreground"]