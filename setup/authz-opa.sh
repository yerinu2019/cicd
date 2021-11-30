#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
./argocd-login.sh
#Uncomment argocd cluster when using cluster1
argocd cluster add gke_monorepotest-323514_us-central1-a_cluster1 -y

kubectl apply -f ../authz/graphql/argocd/authz-opa.yaml
argocd app wait authz-opa

#kubectl -n api-istio apply -f authz-opa/opa-envoy-filter.yaml
#kubectl -n api-istio apply -f authz-opa/opa-rbac.yaml
#kubectl -n api-istio apply -f authz-opa/opa-istio.yaml
#kubectl -n api-istio apply -f authz-opa/gcs-egress.yaml
#kubectl -n api-istio apply -f authz-opa/rego-configmap.yaml
