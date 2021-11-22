#!/bin/bash
kubectl apply -f argocd/namespace.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch service argocd-server --patch-file patch.yaml