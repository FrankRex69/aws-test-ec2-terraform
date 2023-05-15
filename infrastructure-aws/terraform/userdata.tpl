#!/bin/bash
{* BEWARE: Sometimes after the execution of the apt-get upgrade command a restart is required *}

sudo apt update

{* INSTALL NGINX *}
sudo apt install -y nginx

{* INSTALL NODE, NPM *}
sudo apt install nodejs -y
sudo apt install npm -y

{* CLONE AND SETUP APP FROM GITHUB *}
cd /var/www/html/
sudo git clone https://github.com/FrankRex69/bcm
cd /var/www/html/bcm/
sudo npm run install:all

{* INSTALL AND SETUP PM2 *}
sudo npm install pm2 -g
{* setup PM2 for BACKEND *}
cd /var/www/html/bcm/backend/
sudo pm2 start main.js --name "backend"
sudo pm2 save
{* setup PM2 for FRONTEND REACT *}
cd /var/www/html/bcm/frontend-react-noframework/
sudo npm run build
sudo pm2 serve build/ 3000 --name "frontend" --spa 
sudo pm2 save

{* SETUP PROXY SERVER NGINX *}
cd /etc/nginx/sites-available/
sudo rm default

echo "server {
    # The listen directive serves content based on the port defined
    listen 80; # For IPv4 addresses
    listen [::]:80; # For IPv6 addresses

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    # Replace the below if you have a domain name pointed to the server
    server_name    _;

    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location / {
        # Specify the proxied server's address
        proxy_pass http://localhost:3000;
    }
}" > /etc/nginx/sites-available/default;

sudo systemctl restart nginx;
