#!/usr/bin/env bash

# SSH parameters
SSH="ssh -o StrictHostKeyChecking=no -i $DEPLOY_KEY $DEPLOY_USER@$DEPLOY_HOST"

# Decrypt deployment key
openssl aes-256-cbc -K $encrypted_1645300b04d0_key -iv $encrypted_1645300b04d0_iv -in deploy.key.enc -out $DEPLOY_KEY -d
chmod 400 $DEPLOY_KEY

# Copy artifact to remote host
scp -o StrictHostKeyChecking=no -i $DEPLOY_KEY dashboard.tgz $DEPLOY_USER@$DEPLOY_HOST:/tmp

# Copy configuration
# TODO: so far it is a manual copy
# openssl enc -aes-256-cbc -pass env:DEPLOY_PASSWORD -d -a -in "config/devternity.yml" 2> /dev/null

# Deploy dashboard code
$SSH sudo mkdir -p /dashboard/config
$SSH sudo tar -zxvf /tmp/dashboard.tgz --no-same-owner -C /dashboard

# Restart service
$SSH <<EOF
  echo ">>>> Stopping service"
  sudo systemctl stop dashing 
  echo ">>>> Installing bundler"
  cd /dashboard && bundler install
  echo ">>>> Enabling service"
  sudo systemctl disable dashing.service
  sudo systemctl daemon-reload
  sudo systemctl enable /dashboard/dashing.service
  sudo systemctl daemon-reload
  echo ">>>> Restarting service"
  sudo systemctl start dashing 
  echo ">>>> Sleeping"
  sleep 20
  echo ">>>> Showing logs"
  sudo journalctl -xn --no-pager -u dashing.service
  echo ">>>> Checking status"
  sudo systemctl -q is-active dashing
EOF
