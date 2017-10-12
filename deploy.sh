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

# Restart service
$SSH <<EOF
  cd /dashboard && bundler install
  sudo systemctl enable /dashboard/dashing.service
  sudo service dashing restart
  sleep 5
  sudo systemctl -q is-active dashing
EOF
