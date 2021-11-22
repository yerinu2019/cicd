#!/bin/bash
# login to argocd using the initial admin secret
argocd login argocd.svc.yerinu.com --insecure --username admin --password `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
