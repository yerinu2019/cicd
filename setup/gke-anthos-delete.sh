#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: gke-delete.sh <cluster-name>"
    exit 255
fi

gcloud container hub memberships unregister $1
gke-delete.sh $1