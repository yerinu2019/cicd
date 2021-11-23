#!/bin/bash
if [ "$#" < 1 ]; then
    echo "Usage: gke-delete.sh <cluster-name>"
    exit -1
fi

source ../bash/gke-func.sh
delete-gke $1