#!/bin/bash

NGINX_CONF="/etc/nginx/sites-available/automated-deployment-hv"
WEB_ROOT="/var/www/html/automated-deployment-hv"

#Update system packages
sudo apt update -y

echo "Creating Nginx configuration file..."
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 8080;
    server_name _;

    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    error_page 404 /404.html;
}
EOF

# Enable the configuration
echo "Enabling Nginx configuration..."
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/

# Test and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t && sudo systemctl restart nginx

echo "Nginx setup completed successfully."