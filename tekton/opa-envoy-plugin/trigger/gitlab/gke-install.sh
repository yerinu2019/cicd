#!/bin/bash
./install.sh
kubectl apply -f gke-ingress.yaml
kubectl get ingress el-gitlab-listener-ingress
