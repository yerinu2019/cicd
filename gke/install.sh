#!/bin/bash
gcloud config set project monorepotest-323514
gcloud config set compute/zone us-west1-a
gcloud config set compute/region us-west1

gcloud container clusters create cicd --num-nodes=1
gcloud container clusters get-credentials cicd

#gcloud container clusters create opa-authz --num-nodes=1
#gcloud container clusters get-credentials opa-authz
