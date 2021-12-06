#!/bin/bash
if [[ "$#" -lt 1 ]]; then
    echo "Usage: gke-app-cluster.sh <cluster-name>"
    exit 255
fi
CLUSTER_NAME=$1
./gke-create.sh "${CLUSTER_NAME}" "istio"

# Create GCP service account used by authz-operator kubernetes service account
# authz-operator should be able to create GCP service account that can read GCS bucket and
# bind it with Kubernetes service account. So authz-operator should bind to GCP service account
# that can give GCS permission and can bind GCP service account with Kubernetes service account
source ../gke-func.sh
create-gcp-service-account "gcp-authz-operator"
bind-role "gcp-authz-operator" "roles/storage.objectAdmin"
bind-role "gcp-authz-operator" "roles/iam.serviceAccountAdmin"
use-workload-identity "gcp-authz-operator" "opa-istio" "authz-operator"

