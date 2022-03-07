#!/bin/bash
if [[ "$#" -lt 1 ]]; then
    echo "Usage: gke-create.sh <cluster-name> [<num-nodes> istio <zone> <region> <gcp-project>]"
    exit 255
fi

source ../bash/gke-func.sh
MY_CLUSTER_NAME=$1                                    # gke cluster name
NUM_NODES=${2:-"1"}
ISTIO=${3:-"false"}                                   # enable istio
MY_ZONE=${4:-"us-central1-a"}                         # default zone if not set
MY_REGION=${5:-"us-central1"}                         # default region if not set
MY_PROJECT=${6:-"$(gcloud config get-value project)"} # default project if not set
CPU=${7:-"2"}
MEM=${8:-"8"}

create-gke $MY_CLUSTER_NAME $MY_ZONE $MY_REGION $MY_PROJECT $NUM_NODES $CPU $MEM
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
