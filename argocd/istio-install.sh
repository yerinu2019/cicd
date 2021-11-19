#!/bin/bash
./create-cluster.sh

kubectl config use-context gke_monorepotest-323514_us-west1-a_cicd
kubectl apply -k bootstrap/argocd-istio-bootstrap

echo "Expose argocd api server"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl -n argocd get all

echo "Initial admin secret"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d