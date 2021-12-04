#!/bin/bash

function gcp::bind_gcp_service_account() {
  # Bind a kubernetes service account to GCP service account
  if [[ "$#" -ne 3 ]]; then
      echo "Usage: gcp::bind_gcp_service_accounts <gcp service account> <k8s service account> <namespace>"
      exit -1
  fi

  GCP_SERVICE_ACCOUNT=$1
  K8S_SERVICE_ACCOUNT=$2
  K8S_NAMESPACE=$3
  GCP_PROJECT_ID=$(gcloud config get-value project)
  ANNOTATION_KEY_SEARCH="iam\.gke\.io/gcp-service-account"
  ANNOTATION_KEY="iam.gke.io/gcp-service-account"
  ANNOTATION_VALUE="${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

  # Add service account annotation to GCP service account
  CHECK=`kubectl -n ${K8S_NAMESPACE} get sa ${K8S_SERVICE_ACCOUNT} -o jsonpath="{.metadata.annotations.${ANNOTATION_KEY_SEARCH}}"`
  if [[ -z "${CHECK}" ]]; then
    kubectl annotate sa \
          -n ${K8S_NAMESPACE} ${K8S_SERVICE_ACCOUNT} \
          ${ANNOTATION_KEY}=${ANNOTATION_VALUE}
  fi

  # Bind service service account to workloadIdentity user
  # Do not use service account keys.
  # One GCP service account can have only 10 keys
  # It is harder to manage keys
  gcloud iam service-accounts add-iam-policy-binding ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"
}