#!/bin/bash
source source /hooks/common/gcp.sh

k8s::service-account-filter() {
  if [[ "$#" -ne 1 ]]; then
      echo "Usage: k8s::service-account-filter <label>"
      exit -1
  fi
  LABEL=$1
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

function k8s::bind-gcp-service-account() {
  if [[ "$#" -ne 1 ]]; then
      echo "Usage: k8s::bind-gcp-service-account <gcp service account>"
      exit -1
  fi
  GCP_SERVICE_ACCOUNT=$1
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
        gcp::bind_gcp_service_account $GCP_SERVICE_ACCOUNT $sa_name $sa_namespace
      fi
    fi
  done
}