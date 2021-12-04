#!/bin/bash
if [[ "$#" -lt 1 ]]; then
    echo "Usage: gke-create.sh <cluster-name> [istio <zone> <region> <gcp-project>]"
    exit 255
fi

source ../bash/gke-func.sh
MY_CLUSTER_NAME=$1                                    # gke cluster name
ISTIO=${2:-"false"}                                   # enable istio
MY_ZONE=${3:-"us-central1-a"}                         # default zone if not set
MY_REGION=${4:-"us-central1"}                         # default region if not set
MY_PROJECT=${5:-"$(gcloud config get-value project)"} # default project if not set

create-gke "$MY_CLUSTER_NAME"
switch-gke "$MY_CLUSTER_NAME"

if [[ $ISTIO == "istio" ]]; then
  istioctl install --set profile=demo -y
fi

export GCP_SERVICE_ACCOUNT="external-dns"
export K8S_NAMESPACE="default"
export K8S_SERVICE_ACCOUNT="external-dns"

create-gcp-service-account $GCP_SERVICE_ACCOUNT
bind-role $GCP_SERVICE_ACCOUNT "roles/editor"
use-workload-identity $GCP_SERVICE_ACCOUNT $K8S_NAMESPACE $K8S_SERVICE_ACCOUNT
