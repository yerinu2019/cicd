#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
./argocd-login.sh
#Uncomment argocd cluster when using cluster1
argocd cluster add gke_monorepotest-323514_us-central1-a_cluster1 -y

kubectl apply -f /authz/graphql/argocd/authz-namespace.yaml
argocd app wait authz-namespace

switch-gke "cluster1"
kubectl get ns