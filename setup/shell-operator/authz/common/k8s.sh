#!/bin/bash
. /common/gcp.sh

function k8s::resource-label-filter() {
  if [[ "$#" -ne 6 ]]; then
      echo "Usage: k8s::resource-label-filter <api group> <api version> <resource type> <label> <label-value> <shell-operator snapshot name>"
      exit 255
  fi
  API_GROUP=$1
  API_VERSION=$2
  RESOURCE_TYPE=$3
  LABEL=$4
  LABEL_VALUE=$5
  SNAPSHOT_NAME=$6
  cat <<EOF
    configVersion: ${API_VERSION}
    kubernetes:
      -
        apiVersion: ${API_GROUP}/${API_VERSION}
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

  if [[ ${RESOURCE_TYPE,,} == "namespace" ]]; then
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