#!/bin/bash
if [[ "$#" -lt 1 ]]; then
    echo "Usage: anthos-create-cluster.sh <cluster-name>"
    exit 255
fi
CLUSTER_NAME=$1
CLUSTER_LOCATION=${2:-"us-central1-a"}
PROJECT_ID=$(gcloud config get-value project)

gcloud container clusters create "${CLUSTER_NAME} \
    --project="${PROJECT_ID}" \
    --zone="${CLUSTER_LOCATION}" \
    --machine-type=e2-standard-4 \
    --num-nodes=2 \
    --workload-pool="${PROJECT_ID}".svc.id.goog

gcloud container clusters get-credentials "${CLUSTER_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${CLUSTER_LOCATION}"

kubectl config set-context "${CLUSTER_NAME}"

FLEET_PROJECT_ID="${PROJECT_ID}"
DIR_PATH="$HOME/asm"
asmcli install \
  --project_id "${PROJECT_ID}" \
  --cluster_name "${CLUSTER_NAME}" \
  --cluster_location "${CLUSTER_LOCATION}" \
  --fleet_id "${FLEET_PROJECT_ID}" \
  --output_dir "${DIR_PATH}" \
  --enable_all  \
  --ca mesh_ca

GATEWAY_NAMESPACE="gateway"
kubectl create namespace "${GATEWAY_NAMESPACE}"

REVISION=$(kubectl get deploy -n istio-system -l app=istiod -o jsonpath={.items[*].metadata.labels.'istio\.io\/rev'})
kubectl label namespace "${GATEWAY_NAMESPACE}" istio.io/rev="${REVISION}" --overwrite

CURRENT_DIR=~/src/cicd/setup
cd "${DIR_PATH}"/samples
kubectl apply -n "${GATEWAY_NAMESPACE}" -f "${DIR_PATH}"/samples/gateways/istio-ingressgateway
cd "${CURRENT_DIR}"

gcloud container hub cloudrun enable --project="${PROJECT_ID}"
gcloud container hub features list  --project="${PROJECT_ID}"
gcloud container hub cloudrun apply --gke-cluster="$(CLUSTER_LOCATION)"/"${CLUSTER_NAME}"

MEMBERSHIP_NAME="${CLUSTER_NAME}"
gcloud container hub memberships register "${MEMBERSHIP_NAME}" \
 --gke-cluster="$(CLUSTER_LOCATION)"/"${CLUSTER_NAME}" \
 --enable-workload-identity

gcloud container hub memberships describe "${MEMBERSHIP_NAME}"

OPA_LOG_COLLECTOR="opa-log-collector"
gcloud iam service-accounts create "${OPA_LOG_COLLECTOR}" --project="${PROJECT_ID}"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${OPA_LOG_COLLECTOR}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/gkemulticloud.telemetryWriter"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
--member=serviceAccount:"${OPA_LOG_COLLECTOR}"@"${PROJECT_ID}".iam.gserviceaccount.com \
--role=roles/monitoring.metricWriter

gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[knative-serving/controller]" \
    "${OPA_LOG_COLLECTOR}"@"${PROJECT_ID}".iam.gserviceaccount.com

kubectl annotate serviceaccount \
    --namespace knative-serving controller \
    iam.gke.io/gcp-service-account="${OPA_LOG_COLLECTOR}"@"${PROJECT_ID}".iam.gserviceaccount.com

