#!/usr/bin/env bash
# Create or delete clusterrolebindings, rolebindings and roles for namespace where label
# authz-opa-istio-injection is enabled
source /shell_lib.sh

LABEL="authz-opa-istio-injection"
POLICY_MONITOR_NAME="graphql-policy-monitor"
OPA_VIEWER_NAME="opa-viewer"
CONFIGMAP_MODIFIER_NAME="opa-configmap-modifier"

function __config__() {
  cat <<EOF
configVersion: v1
kubernetes:
  -
    apiVersion: v1
    group: main
    jqFilter: |
        {
          namespace: .metadata.name,
          hasLabel: (
           .metadata.labels // {} |
             contains({"${LABEL}": "enabled"})
          )
        }
    keepFullObjectsInMemory: false
    kind: Namespace
    name: namespaces
  -
    apiVersion: rbac.authorization.k8s.io/v1
    jqFilter: |
        {
          "name": .metadata.name,
        }
    keepFullObjectsInMemory: false
    kind: ClusterRoleBinding
    labelSelector:
      matchLabels:
        "${LABEL}": "enabled"
    name: cluster-roles
  -
    apiVersion: rbac.authorization.k8s.io/v1
    jqFilter: |
        {
          "namespace": .metadata.namespace,
          "name": .metadata.name,
        }
    keepFullObjectsInMemory: false
    kind: RoleBinding
    labelSelector:
      matchLabels:
        "${LABEL}": enabled
    name: roles
EOF
}

function enable_rbac() {
  ns_name=$1
  cat <<EOF  | kubectl apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${POLICY_MONITOR_NAME}
rules:
  - apiGroups: ["example.com"]
    resources: ["graphqlpolicies"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${POLICY_MONITOR_NAME}-${ns_name}
  metadata:
    labels"
      ${LABEL}: "enabled"
roleRef:
  kind: ClusterRole
  name: ${POLICY_MONITOR_NAME}
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: Group
    name: system:serviceaccounts:${ns_name}
    apiGroup: rbac.authorization.k8s.io
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${OPA_VIEWER_NAME}-${ns_name}
  labels:
    ${LABEL}: "enabled"
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: Group
    name: system:serviceaccounts:${ns_name}
    apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${CONFIGMAP_MODIFIER_NAME}
  namespace: ${ns_name}
  labels:
      ${LABEL}: "enabled"
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${CONFIGMAP_MODIFIER_NAME}
  labels:
    ${LABEL}: "enabled"
roleRef:
  kind: Role
  name: ${CONFIGMAP_MODIFIER_NAME}
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: Group
    name: system:serviceaccounts:${ns_name}
    apiGroup: rbac.authorization.k8s.io
EOF
}

function disable_rbac() {
  ns_name=$1
  for i in $(seq 0 "$(context::jq -r '(.snapshots.cluster-roles | length) - 1')"); do
    name="$(context.jq -r '.snapshots.cluster-roles['"$i"'].filterResult.name')"
    kubectl -n ${ns_name} delete clusterrolebinding ${name}
  done

  for i in $(seq 0 "$(context::jq -r '(.snapshots.cluster-roles | length) - 1')"); do
    namespace="$(context.jq -r '.snapshots.roles['"$i"'].filterResult.namespace')"
    if [[ $namespace -eq $ns_name ]]; then
      name="$(context.jq -r '.snapshots.roles['"$i"'].filterResult.name')"
      kubectl -n ${namespace} delete rolebindings ${name}
    fi
  done
}

function __main__() {
  for i in $(seq 0 "$(context::jq -r '(.snapshots.namespaces | length) - 1')"); do
    echo "check ns_name"
    ns_name="$(context::jq -r '.snapshots.namespaces['"$i"'].filterResult.name')"
    echo "ns_name: ${ns_name}"
    if context::jq -e '.snapshots.namespaces['"$i"'].filterResult.hasLabel' ; then
      enable_rbac "$ns_name"
    else
      disable_rbac "$ns_name"
    fi
  done
}

hook::run "$@"