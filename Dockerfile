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

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory
WORKDIR /var/www/html

# Copy configuration files first
COPY package*.json composer.json composer.lock ./
COPY vite.config.js postcss.config.js tailwind.config.js ./

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

# Ensure required directories exist with proper permissions
RUN mkdir -p public/build/assets
RUN mkdir -p resources/css resources/js
RUN chmod -R 775 public/build

# Create basic app.js if it doesn't exist
RUN if [ ! -f resources/js/app.js ]; then \
    echo "import './bootstrap';\nimport '../css/app.css';" > resources/js/app.js; \
    fi

# Create basic app.css if it doesn't exist
RUN if [ ! -f resources/css/app.css ]; then \
    echo "@tailwind base;\n@tailwind components;\n@tailwind utilities;" > resources/css/app.css; \
    fi

# Clear any existing build files
RUN rm -rf public/build/*

# Build assets with detailed output
RUN NODE_ENV=production npm run build

# Ensure manifest exists and is in the correct location
RUN if [ -f public/build/.vite/manifest.json ]; then \
    mkdir -p public/build && \
    cp public/build/.vite/manifest.json public/build/manifest.json; \
    fi

# Debug: Show build contents
RUN echo "Build directory contents:" && ls -la public/build/
RUN echo "Assets directory contents:" && ls -la public/build/assets/ || true
RUN echo "Manifest contents:" && cat public/build/manifest.json || true

# Configure Apache
RUN sed -i 's|/var/www/html|/var/www/html/public|' /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 775 storage bootstrap/cache public/build

EXPOSE 80

CMD ["sh", "-c", "php artisan migrate --force && apache2-foreground"]