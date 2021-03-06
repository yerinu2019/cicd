#!/bin/bash

cd ./shell-operator/authz
./make.sh
cd ../..

source ../bash/gke-func.sh

switch-gke "cicd"
./argocd-login.sh
#Uncomment argocd cluster when using cluster1
argocd cluster add gke_monorepotest-323514_us-central1-a_cluster1 -y

kubectl apply -f ../authz/graphql/argocd/authz-operator.yaml

switch-gke "cluster1"
kubectl -n opa-istio rollout restart deployment authz-operator
kubectl -n opa-istio rollout status deployment/authz-operator
kubectl get clusterrolebindings | grep opa-istio
kubectl -n opa-istio get rolebindings