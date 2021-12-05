#!/bin/bash
. /common/gcp.sh

function k8s::resource-label-filter() {
  if [[ "$#" -ne 4 ]]; then
      echo "Usage: k8s::resource-label-filter <resource type> <label> <label-value> <shell-operator snapshot name>"
      exit 255
  fi
  RESOURCE_TYPE=$1
  LABEL=$2
  LABEL_VALUE=$3
  SNAPSHOT_NAME=$4
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
              opa-config: .metadata.annotations.opa-config,
              labelMatched: (
               .metadata.labels // {} |
                 contains({"${LABEL}": "${LABEL_VALUE}"})
              )
            }
        keepFullObjectsInMemory: false
        kind: ${RESOURCE_TYPE}
        name: ${SNAPSHOT_NAME}
EOF
}

function k8s::label() {
  if [[ "$#" -ne 5 ]]; then
      echo "Usage: k8s::label <namespace> <resource-type> <name> <label> <label-value>"
      exit 255
  fi
  NAMESPACE=$1
  RESOURCE_TYPE=$2
  NAME=$3
  LABEL=$4
  VALUE=$5

  if [[ ${RESOURCE_TYPE,,} -eq "namespace"]]]; then
    CHECK=$(kubectl get ns ${NAMESPACE} -o jsonpath="{.metadata.labels.${LABEL}}")
    if [[ -z "${CHECK}" ]]; then
      kubectl label namespace ${NAMESPACE} ${LABEL}="${VALUE}"
    fi
  else
    CHECK=$(kubectl -n ${NAMESPACE} get ${RESOURCE_TYPE} -o jsonpath="{.metadata.labels.${LABEL}}")
    if [[ -z "${CHECK}" ]]; then
      kubectl label -n ${NAMESPACE} ${RESOURCE_TYPE} ${LABEL}="${VALUE}"
    fi
  fi
}

function k8s::ensure_istio_enabled() {
  if [[ "$#" -ne 1 ]]; then
      echo "Usage: k8s::ensure_istio_enabled <namespace>"
      exit 255
  fi
  NAMESPACE=$1
  LABEL="istio-injection"
  k8s::label $NAMESPACE namespace $NAMESPACE $LABEL "enabled"
}

function k8s::service-account-filter() {
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