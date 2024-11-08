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

# Install Node.js 20.x (for Vite 5.0 compatibility)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory
WORKDIR /var/www/html

# Copy package files first
COPY package*.json ./
COPY composer.json composer.lock ./
COPY vite.config.js tailwind.config.js postcss.config.js ./

# Show versions for debugging
RUN node -v && npm -v

# Install dependencies
RUN npm install
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy the rest of the application
COPY . .

# Set up environment file
RUN cp .env.example .env
RUN php artisan key:generate --ansi

# Create necessary directories
RUN mkdir -p public/build
RUN mkdir -p resources/css resources/js

# Build assets
RUN npm run build

# Debug: Show contents of build directory
RUN ls -la public/build

# Configure Apache
RUN sed -i 's|/var/www/html|/var/www/html/public|' /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 775 storage bootstrap/cache public/build

EXPOSE 80

CMD ["sh", "-c", "php artisan migrate --force && apache2-foreground"]