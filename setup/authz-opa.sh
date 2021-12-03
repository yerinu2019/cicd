#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
./argocd-login.sh
#Uncomment argocd cluster when using cluster1
argocd cluster add gke_monorepotest-323514_us-central1-a_cluster1 -y

kubectl apply -f ../authz/graphql/argocd/authz-istio-envoy-filter.yaml
kubectl apply -k ../authz/graphql/argocd/authz-opa-istio/overlays/gke_monorepotest-323514_us-central1-a_cluster1/api-istio
kubectl apply -f ../authz/graphql/argocd/authz-gcs-egress.yaml
kubectl apply -f ../authz/graphql/argocd/authz-rego-configmap.yaml


