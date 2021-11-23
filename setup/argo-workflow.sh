#!/bin/bash
kubectl apply -k argo-workflow
kubectl -n argo patch service argo-server --patch-file argo-workflow/patch.yaml