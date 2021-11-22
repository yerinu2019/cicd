#!/bin/bash
source ../bash/gke-func.sh

switch-gke "cluster1"
kubectl apply -k ./authz-acl