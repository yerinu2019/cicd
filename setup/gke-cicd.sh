#!/bin/bash
CLUSTER_NAME="cicd"
echo "Create GKE cicd"
source ../bash/gke-func.sh
create-gke $CLUSTER_NAME

gcloud container clusters update $CLUSTER_NAME \
    --update-addons ConfigConnector=ENABLED

export GCP_PROJECT_ID=`gcloud config get-value project`
export GCP_SERVICE_ACCOUNT="cicd-sa"
export K8S_NAMESPACE="default"
export K8S_SERVICE_ACCOUNT="cicd-sa"

create-gcp-service-account $GCP_SERVICE_ACCOUNT
bind-role $GCP_SERVICE_ACCOUNT "roles/storage.objectAdmin"
use-workload-identity $GCP_SERVICE_ACCOUNT $K8S_NAMESPACE $K8S_SERVICE_ACCOUNT
