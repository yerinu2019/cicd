#!/bin/bash
# Create GCP service account for k8s service account
source /shell_lib.sh
LABEL="authz-opa-istio-injection"
function __config__() {
  cat <<EOF
  configVersion: v1
  kubernetes:
    -
      apiVersion: v1
      group: main
      jqFilter: |
          {
            name: .metadata.name,
            namespace: .metadata.namespace,
            hasLabel: (
             .metadata.labels // {} |
               contains({"${LABEL}": "enabled"})
            )
          }
      keepFullObjectsInMemory: false
      kind: ServiceAccount
      name: sa
  EOF
}

function bind_gcs_reader() {
  GCP_SERVICE_ACCOUNT="gcs-reader"
  K8S_SERVICE_ACCOUNT=$1
  K8S_NAMESPACE=$2
  GCP_PROJECT_ID=$(gcloud config get-value project)
  gcloud iam service-accounts add-iam-policy-binding ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"
  CHECK=`kubectl -n ${K8S_NAMESPACE} describe sa ${K8S_SERVICE_ACCOUNT} | grep iam.gke.io/gcp-service-account`
  if [[ -z "${CHECK}" ]]; then
    kubectl annotate sa \
          -n ${K8S_NAMESPACE} ${K8S_SERVICE_ACCOUNT} \
          iam.gke.io/gcp-service-account=${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com
  fi
}

function __main__() {
  for i in $(seq 0 "$(context::jq -r '(.snapshots.sa | length) - 1')"); do
    echo
    echo "check name"
    sa_name="$(context::jq -r '.snapshots.sa['"$i"'].filterResult.name')"
    sa_namespace="$(context::jq -r '.snapshots.sa['"$i"'].filterResult.namespace')"
    echo "name: ${sa_name}"
    if [[ -z sa_name || "$sa_name" == "null" ]]; then
      echo "skip null sa_name"
    else
      if context::jq -e '.snapshots.sa['"$i"'].filterResult.hasLabel' ; then
        bind_gcs_reader $sa_name $sa_namespace
      fi
    fi
  done
}

hook::run "$@"