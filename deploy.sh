#!/usr/bin/env bash

set -e

# SSH parameters
SSH="ssh -o StrictHostKeyChecking=no -i $DEPLOY_KEY $DEPLOY_USER@$DEPLOY_HOST"
SCP="scp -o StrictHostKeyChecking=no -i $DEPLOY_KEY"

# Decrypt deployment key
openssl aes-256-cbc -K $encrypted_1645300b04d0_key -iv $encrypted_1645300b04d0_iv -in deploy.key.enc -out $DEPLOY_KEY -d
chmod 400 $DEPLOY_KEY

# Decrypt configuration
function decrypt() {
  filename="$1"
  openssl enc -aes-256-cbc -pass env:SECRET_PASSWORD -d -a -in "${filename}" -out "${filename}.dec" && rm -f "${filename}" && mv "${filename}.dec" "${filename}"
} 
decrypt config/integrations.yml
decrypt config/firebase-sales.json
decrypt config/firebase-voting.json

# Create dashboard artifact 
rm -rf dashboard.tgz
tar -czf dashboard.tgz ./config ./assets ./dashboards ./jobs ./public ./widgets ./config.ru ./Gemfile* ./smashing.service

# Copy artifacts to remote host
$SCP dashboard.tgz $DEPLOY_USER@$DEPLOY_HOST:/tmp
$SCP smashing.nginx $DEPLOY_USER@$DEPLOY_HOST:/tmp
rm -rf dashboard.tgz
rm -rf config/*

# Create or renew certificate
decrypt ./cloudflare.ini
$SSH sudo systemctl stop nginx || true
$SSH sudo mkdir -p /home/$DEPLOY_USER/.secrets/certbot
$SSH sudo chown $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.secrets
$SSH sudo chown $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.secrets/certbot
$SCP ./cloudflare.ini $DEPLOY_USER@$DEPLOY_HOST:/home/$DEPLOY_USER/.secrets/certbot
# Uncomment the following line if certificate regeneration is required
# $SSH sudo docker run --rm --name certbot -p 80:80 -p 443:443 -v /etc/letsencrypt:/etc/letsencrypt/ -v /var/log/letsencrypt:/var/log/letsencrypt -v /home/$DEPLOY_USER/.secrets/certbot:/secrets certbot/dns-cloudflare certonly --dns-cloudflare --dns-cloudflare-credentials /secrets/cloudflare.ini --dns-cloudflare-propagation-seconds 60 -n --agree-tos -m andrey@aestasit.com -d internal.devternity.com --server https://acme-v02.api.letsencrypt.org/directory
$SSH sudo rm -rf /home/$DEPLOY_USER/.secrets
rm -rf ./cloudflare.ini

# Restart service
$SSH <<EOF
  echo ">>>> Stopping service"
  sudo systemctl stop smashing 
  echo ">>>> Deploy dashboard code"
  sudo rm -rf /dashboard/*
  sudo mkdir -p /dashboard/config
  sudo tar -zxvf /tmp/dashboard.tgz --no-same-owner -C /dashboard
  echo ">>>> Deploy proxy"
  sudo apt-get -y install nginx
  yes | sudo cp -rf /tmp/smashing.nginx /etc/nginx/sites-available/default
  echo ">>>> Installing bundler"
  cd /dashboard && bundler install
  echo ">>>> Enabling service"
  sudo systemctl disable smashing.service
  sudo systemctl daemon-reload
  sudo systemctl enable /dashboard/smashing.service
  sudo systemctl daemon-reload
  echo ">>>> Restarting service"
  sudo systemctl start smashing 
  sudo systemctl restart nginx
  echo ">>>> Sleeping"
  sleep 30
  echo ">>>> Showing logs"
  sudo journalctl --no-pager --since "15 minutes ago" -u smashing.service
  echo ">>>> Checking status"
  sudo systemctl -q is-active smashing
EOF
