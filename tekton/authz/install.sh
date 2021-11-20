#!/bin/bash
kubectl apply -f rbac.yaml
kubectl apply -f gitlab-listener.yaml

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)

#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml
#kubectl apply -f gke-ingress.yaml
kubectl get ingress authz-gitlab-listener-ingress
