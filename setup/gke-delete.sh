#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: gke-delete.sh <cluster-name>"
    exit 255
fi

source ../bash/gke-func.sh
delete-gke $1