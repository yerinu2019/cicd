#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cicd"
kubectl apply -k ./authz-acl