#!/bin/bash
./install.sh

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml

kubectl apply -f gke-ingress.yaml
kubectl get ingress el-gitlab-listener-ingress
