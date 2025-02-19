#!/bin/bash

NGINX_CONF="/etc/nginx/sites-available/automated-deployment-hv"
WEB_ROOT="/var/www/html/automated-deployment-hv"

#Update system packages
sudo apt-get update -y

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

# Test and reload Nginx configuration
if sudo nginx -t; then
    sudo nginx -s reload
    echo "Nginx setup completed successfully."
else
    echo "Nginx configuration test failed!" >&2
    exit 1
fi