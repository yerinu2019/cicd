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
  #gcloud iam service-accounts add-iam-policy-binding ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
  #      --role roles/iam.workloadIdentityUser \
  #      --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"

  # Alternative to using workloadIdentity which is only available on GKE
  # 1. Create a key file for GCP service account
  # 2. Create a k8s secret using the key file
  # 3. Associate the secret with the k8s service account
  KEY_FILE="keyfile.json"
  # This is when not using workload Identity
  SECRET_NAME="${GCP_SERVICE_ACCOUNT}-secret"
  echo "kubectl -n ${K8S_NAMESPACE} get sa ${K8S_SERVICE_ACCOUNT} -o json"
  echo `kubectl -n ${K8S_NAMESPACE} get sa ${K8S_SERVICE_ACCOUNT} -o json`
  CHECK=`kubectl -n ${K8S_NAMESPACE} get sa ${K8S_SERVICE_ACCOUNT} -o json | jq -r '.imagePullSecrets[] | select(.name | test("${SECRET_NAME}")).name'`
  if [[ -z "${CHECK}" ]]; then
    # Create secret key file
    gcloud iam service-accounts keys create ${KEY_FILE} \
          --iam-account=${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com

    # Create k8s secret for the gcp service account
    kubectl -n ${K8S_NAMESPACE} create secret generic ${SECRET_NAME} --from-file=key.json=${KEY_FILE}.json

    # Associate the secret with the k8s service account
    kubectl -n ${K8S_NAMESPACE} patch serviceaccount ${K8S_SERVICE_ACCOUNT} -p '{"imagePullSecrets": [{"name": "${SECRET_NAME}"}]}'
  fi
}