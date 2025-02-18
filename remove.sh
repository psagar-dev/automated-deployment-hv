cd /var/www/html && sudo rm -r automated-deployment-hv
cd /home && sudo rm -r ci-cd
cd /etc/nginx/sites-available && sudo rm -r automated-deployment-hv
cd /etc/nginx/sites-enabled && sudo rm -r automated-deployment-hv

sudo nginx -t && sudo systemctl restart nginx