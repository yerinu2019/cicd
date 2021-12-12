#!/bin/bash
if [[ "$#" -lt 1 ]]; then
    echo "Usage: anthos-create-cluster.sh <cluster-name>"
    exit 255
fi
CLUSTER_NAME=$1
CLUSTER_LOCATION=${2:-"us-central1-a"}
PROJECT_ID=$(gcloud config get-value project)

echo "create anthos1 cluster"
gcloud container clusters create "${CLUSTER_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${CLUSTER_LOCATION}" \
    --machine-type=e2-standard-4 \
    --num-nodes=2 \
    --workload-pool="${PROJECT_ID}".svc.id.goog

echo "use anthos1 cluster"
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${CLUSTER_LOCATION}"

kubectl config set-context "${CLUSTER_NAME}"

FLEET_PROJECT_ID="${PROJECT_ID}"
DIR_PATH="$HOME/asm"
echo "install anthos service mesh to cluster anthos1"
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
echo "label gateway namespace"
kubectl label namespace "${GATEWAY_NAMESPACE}" istio.io/rev="${REVISION}" --overwrite

CURRENT_DIR=~/src/cicd/setup
cd "${DIR_PATH}"/samples
echo "enable istio-ingressgateway"
kubectl apply -n "${GATEWAY_NAMESPACE}" -f "${DIR_PATH}"/samples/gateways/istio-ingressgateway
cd "${CURRENT_DIR}"

echo "enable cloudrun in fleet"
gcloud container hub cloudrun enable --project="${PROJECT_ID}"

echo "list features"
gcloud container hub features list  --project="${PROJECT_ID}"

echo "apply cloudrun to gke cluster"
gcloud container hub cloudrun apply --gke-cluster="${CLUSTER_LOCATION}"/"${CLUSTER_NAME}"

MEMBERSHIP_NAME="${CLUSTER_NAME}"
echo "register anthos1 to fleet"
gcloud container hub memberships register "${MEMBERSHIP_NAME}" \
 --gke-cluster="${CLUSTER_LOCATION}"/"${CLUSTER_NAME}" \
 --enable-workload-identity

echo "describe anothos1 memebership to fleet"
gcloud container hub memberships describe "${MEMBERSHIP_NAME}"

OPA_LOG_COLLECTOR="opa-log-collector"
echo "create opa-log-collector service account"
gcloud iam service-accounts create "${OPA_LOG_COLLECTOR}" --project="${PROJECT_ID}"

echo "bind opa-log-collector with gkemulticloud.telemetryWriter role"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${OPA_LOG_COLLECTOR}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/gkemulticloud.telemetryWriter"

echo "bind opa-log-collector to monitoring.metricWriter role"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
--member=serviceAccount:"${OPA_LOG_COLLECTOR}"@"${PROJECT_ID}".iam.gserviceaccount.com \
--role=roles/monitoring.metricWriter

echo "bind opa-log-collector and knative-serving/controller with workload identity user role"
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[knative-serving/controller]" \
    "${OPA_LOG_COLLECTOR}"@"${PROJECT_ID}".iam.gserviceaccount.com

echo "Waiting for namespace being created..."
sleep 10
echo "annotate knative-serving controller"
kubectl annotate serviceaccount \
    --namespace knative-serving controller \
    iam.gke.io/gcp-service-account="${OPA_LOG_COLLECTOR}"@"${PROJECT_ID}".iam.gserviceaccount.com

