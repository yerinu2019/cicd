#!/bin/bash
echo "Create GKE cluster1"
source ../bash/gke-func.sh
create-istio-gke "cluster1"
