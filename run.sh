#!/usr/bin/env bash

IMAGE=devternity-sales
NAME=dashboard
docker build -t ${IMAGE} .

(docker container ls -a | grep ${NAME}) && \
  (docker container rm -fv ${NAME} || echo "Could not remove ${NAME}")

docker run -it \
  -p 3030:3030 \
  -v $PWD:/app \
  --name ${NAME} \
  \
  ${IMAGE}

