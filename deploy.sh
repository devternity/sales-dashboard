#!/usr/bin/env bash

SSH="ssh -o StrictHostKeyChecking=no -i $DEPLOY_KEY $DEPLOY_USER@$DEPLOY_HOST"

# Give correct permissions to the key
chmod 400 $DEPLOY_KEY

# Copy artifact to remote host
scp -o StrictHostKeyChecking=no -i $DEPLOY_KEY dashboard.tgz $DEPLOY_USER@$DEPLOY_HOST:/tmp

# Deploy dashboard code
$SSH sudo mkdir -p /dashboard
$SSH sudo tar -zxvf /tmp/dashboard.tgz --no-same-owner -C /dashboard

# Copy configuration
# TODO: so far it is a manual copy

# Restart service
$SSH <<EOF
  echo ">>>> Installing bundler"
  cd /dashboard && bundler install
  echo ">>>> Enabling service"
  sudo systemctl disalbe dashing.service
  sudo systemctl enable /dashboard/dashing.service
  echo ">>>> Restarting service"
  sudo service dashing restart
  echo ">>>> Sleeping"
  sleep 5
  echo ">>>> Showing logs"
  sudo journalctl -xn --no-pager -u dashing.service
  echo ">>>> Checking status"
  sudo systemctl -q is-active dashing
EOF
