#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
./argocd-login.sh
argocd cluster add gke_monorepotest-323514_us-central1-a_cluster1 -y

kubectl apply -k ./authz-acl