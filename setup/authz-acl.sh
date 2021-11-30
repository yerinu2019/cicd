#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
./argocd-login.sh
#Uncomment argocd cluster when using cluster1
argocd cluster add gke_monorepotest-323514_us-central1-a_cluster1 -y

kubectl apply -f ../authz/graphql/argocd/authz-acl.yaml
argocd app wait authz-acl

switch-gke "cluster1"
kubectl -n api-istio get graphpolicies