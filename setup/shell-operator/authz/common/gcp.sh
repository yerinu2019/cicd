#!/bin/bash

function k8s::ensure_service_account() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: k8s::ensure_service_account <namespace> <name>"
      exit 255
  fi
  NAMESPACE=$1
  NAME=$2
  CHECK=$(kubectl -n "${NAMESPACE}" get sa ${NAME} -o jsonpath="{.metadata.name}")
  if [[ -z "${CHECK}" ]]; then
    kubectl -n "${NAMESPACE}" create sa "${NAME}"
  fi
}

function k8s::annotate() {
  if [[ "$#" -lt 5 ]]; then
      echo "Usage: k8s::annotation <namespace> <resource type> <name> <annotation key> <annotation value> [<annotation key search>]"
      exit 255
  fi
  K8S_NAMESPACE=$1
  RESOURCE_TYPE=$2
  RESOURCE_NAME=$3
  ANNOTATION_KEY=$4
  ANNOTATION_VALUE=$5
  ANNOTATION_KEY_SEARCH=${6:-"${ANNOTATION_KEY}"}

  if [[ ${RESOURCE_TYPE,,} == "namespace" ]]; then
    CHECK=$(kubectl get "${RESOURCE_TYPE}" "${K8S_SERVICE_ACCOUNT}" -o jsonpath="{.metadata.annotations.${ANNOTATION_KEY_SEARCH}}")
    if [[ -z "${CHECK}" ]]; then
      kubectl annotate "${RESOURCE_TYPE}" "${RESOURCE_NAME}" \
            "${K8S_SERVICE_ACCOUNT}" \
            "${ANNOTATION_KEY}"="${ANNOTATION_VALUE}"
    fi
  else
    CHECK=$(kubectl -n "${K8S_NAMESPACE}" get ${RESOURCE_TYPE} "${RESOURCE_NAME}" -o jsonpath="{.metadata.annotations.${ANNOTATION_KEY_SEARCH}}")
    if [[ -z "${CHECK}" ]]; then
      kubectl annotate "${RESOURCE_TYPE}" \
            -n "${K8S_NAMESPACE}" "${RESOURCE_NAME}" \
            "${ANNOTATION_KEY}"="${ANNOTATION_VALUE}"
    fi
  fi
}

function gcp::bind_gcp_service_account() {
  # Bind a kubernetes service account to GCP service account
  if [[ "$#" -ne 3 ]]; then
      echo "Usage: gcp::bind_gcp_service_accounts <gcp service account> <k8s service account> <k8s namespace>"
      exit 255
  fi

  GCP_SERVICE_ACCOUNT=$1
  K8S_SERVICE_ACCOUNT=$2
  K8S_NAMESPACE=${3:-"default"}
  ANNOTATION_KEY_SEARCH="iam\.gke\.io/gcp-service-account"
  ANNOTATION_KEY="iam.gke.io/gcp-service-account"
  ANNOTATION_VALUE="${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

  k8s::ensure_service_account "${K8S_NAMESPACE}" "${K8S_SERVICE_ACCOUNT}"
  k8s::annotate "${K8S_NAMESPACE}" sa "${K8S_SERVICE_ACCOUNT}" ${ANNOTATION_KEY} "${ANNOTATION_VALUE}" ${ANNOTATION_KEY_SEARCH}

  # Bind service service account to workloadIdentity user
  # Do not use service account keys.
  # One GCP service account can have only 10 keys
  # It is harder to manage keys
  GCP_PROJECT_ID=$(gcloud config get-value project)
  gcloud iam service-accounts add-iam-policy-binding "${GCP_SERVICE_ACCOUNT}"@"${GCP_PROJECT_ID}".iam.gserviceaccount.com \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"
}

function gcp::create-gcp-service-account() {
  if [[ "$#" -ne 1 ]]; then
      echo "Usage: create-gcp-service-account <gcp service account>"
      exit 255
  fi
  GSA=$1
  CHECK=$(gcloud iam service-accounts list | grep "${GSA}"@)
  echo "Check Google Service Account Result for ${GSA}@: ${CHECK}"
  if [[ -z "${CHECK}" ]]; then
    echo "Create GCP Service Account ${GSA}"
    gcloud iam service-accounts create "${GSA}"
  else
    echo "GCP Service Account $GSA exists."
  fi
}

function gcp::bind-role() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: bind-role <gcp service account> <role>"
      exit 255
  fi
  GCP_PROJECT_ID=$(gcloud config get-value project)
  GCP_SERVICE_ACCOUNT=$1
  ROLE=$2
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
      --member "serviceAccount:${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
      --role "${ROLE}"
}
