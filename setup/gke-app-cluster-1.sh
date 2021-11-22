#!/bin/bash
# application cluster with istio
CLUSTER_NAME="cluster1"
echo "Create GKE cluster1"
source ../bash/gke-func.sh
create-gke $CLUSTER_NAME
switch-gke $CLUSTER_NAME
echo "Install Istio"
istioctl install --set profile=demo -y