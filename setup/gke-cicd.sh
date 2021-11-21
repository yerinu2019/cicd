#!/bin/bash
echo "Create GKE cicd"
source ../bash/gke-func.sh
create-gke "cicd"
