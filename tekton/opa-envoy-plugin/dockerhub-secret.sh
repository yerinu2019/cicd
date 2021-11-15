#!/bin/bash
# create kubernetes secret for docker hub
kubectl delete secret dockerhub-credential
kubectl create secret docker-registry dockerhub-credential \
--docker-server=${DOCKER_HUB_SERVER} \
--docker-username=${DOCKER_HUB_USER} \
--docker-password=${DOCKER_HUB_PASSWORD} \
--docker-email=${DOCKER_HUB_EMAIL}