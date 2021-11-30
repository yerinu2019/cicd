#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo