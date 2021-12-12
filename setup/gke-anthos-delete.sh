#!/bin/bash
if [ "$#" -lt 2 ]; then
    echo "Usage: gke-delete.sh <cluster-name> <location-name>"
    exit 255
fi
CLUSTER_NAME=$1
LOCATION_NAME=$2
gcloud container hub memberships unregister "${CLUSTER_NAME}" --gke-cluster="${LOCATION_NAME}/${CLUSTER_NAME}"
./gke-delete.sh "${CLUSTER_NAME}"