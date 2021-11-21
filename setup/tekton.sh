#!/bin/bash

kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
kubectl annotate -n tekton-pipelines svc tekton-dashboard external-dns.alpha.kubernetes.io/hostname=tekton.svc.yerinu.com.
kubectl apply -f tekton-rbac.yaml
