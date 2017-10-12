#!/usr/bin/env bash

SSH="ssh -t -o StrictHostKeyChecking=no -i $DEPLOY_KEY $DEPLOY_USER@$DEPLOY_HOST"
COPY="$SSH 'sudo tar -x --no-same-owner -C /dashboard'"

$SSH sudo mkdir -p /dashboard
tar -c -C ./assets ./dashboards ./jobs ./public ./widgets ./config.ru ./Gemfile* ./dashing.service | $COPY

$SSH <<EOF
  cd /dashboard && bundler install
  sudo systemctl enable dashing.service
  sudo service dashing restart
EOF
