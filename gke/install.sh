#!/bin/bash
source ../bash/gke-func.sh
create-gke "monorepotest-323514" "us-central1-a" "us-central1" "cicd"
#create-gke "monorepotest-323514" "us-central1-a" "us-central1" "opa"

#gcloud container clusters create opa-authz --num-nodes=1
#gcloud container clusters get-credentials opa-authz
