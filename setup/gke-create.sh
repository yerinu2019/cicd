#!/bin/bash
if [[ "$#" -lt 1 ]]; then
    echo "Usage: gke-create.sh <cluster-name> [istio <zone> <region> <gcp-project>]"
    exit -1
fi

source ../bash/gke-func.sh
MY_CLUSTER_NAME=$1                                    # gke cluster name
ISTIO=${2:-"false"}                                   # enable istio
MY_ZONE=${3:-"us-central1-a"}                         # default zone if not set
MY_REGION=${4:-"us-central1"}                         # default region if not set
MY_PROJECT=${5:-"$(gcloud config get-value project)"} # default project if not set

create-gke $CLUSTER_NAME

current-gke-cluster
CURRENT_CLUSTER=$__

SWITCHED=false
if [[ $CURRENT_CLUSTER -ne $MY_CLUSTER_NAME ]]; then
  switch-gke $MY_CLUSTER_NAME
  SWITCHED=true
else
  gcloud container clusters get-credentials $MY_CLUSTER_NAME --zone $MY_ZONE -q
fi

if [[ $ISTIO -eq "istio" ]]; then
  istioctl install --set profile=demo -y
fi

export GCP_SERVICE_ACCOUNT="${MY_CLUSTER_NAME}-sa"
export K8S_NAMESPACE="default"
export K8S_SERVICE_ACCOUNT="${MY_CLUSTER_NAME}"

create-gcp-service-account $GCP_SERVICE_ACCOUNT
bind-role $GCP_SERVICE_ACCOUNT "roles/storage.objectAdmin"
use-workload-identity $GCP_SERVICE_ACCOUNT $K8S_NAMESPACE $K8S_SERVICE_ACCOUNT

export GCP_SERVICE_ACCOUNT="external-dns"
export K8S_NAMESPACE="default"
export K8S_SERVICE_ACCOUNT="external-dns"

create-gcp-service-account $GCP_SERVICE_ACCOUNT
bind-role $GCP_SERVICE_ACCOUNT "roles/editor"
use-workload-identity $GCP_SERVICE_ACCOUNT $K8S_NAMESPACE $K8S_SERVICE_ACCOUNT

# install argo events to all gke cluster
./argo-events.sh

if [[ "$SWITCHED" = true ]]; then
  switch-gke $CURRENT_CLUSTER
fi
