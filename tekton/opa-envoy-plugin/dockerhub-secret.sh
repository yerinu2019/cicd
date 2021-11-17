#!/bin/bash
# create kubernetes secret for docker hub
kubectl delete secret dockerhub-credential

export DOCKER_HUB_USER=$1
set +H
export DOCKER_HUB_PASSWORD=$2
set -H
export DOCKER_HUB_EMAIL=$3

kubectl create secret docker-registry dockerhub-credential \
--docker-server=https://index.docker.io/v1/ \
--docker-username=${DOCKER_HUB_USER} \
--docker-password=${DOCKER_HUB_PASSWORD} \
--docker-email=${DOCKER_HUB_EMAIL}