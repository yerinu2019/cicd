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
- name: namespaces
  group: main
  apiVersion: v1
  kind: Namespace
  jqFilter: |
    {
      namespace: .metadata.name,
      hasLabel: (
       .metadata.labels // {} |
         contains({"${LABEL}": "enabled"})
      )
    }
  group: main
  keepFullObjectsInMemory: false
- name: cluster-roles
  apiVersion: v1
  kind: ClusterRoleBinding
  labelSelector:
    matchLabels:
      ${LABEL}: "enabled"
  jqFilter: |
    {
      "name": .metadata.name,
    }
  keepFullObjectsInMemory: false
- name: roles
  apiVersion: v1
  kind: RoleBinding
  labelSelector:
    matchLabels:
      ${LABEL}: "enabled"
 jqFilter: |
   {
     "namespace": .metadata.namespace,
     "name": .metadata.name,
   }
  keepFullObjectsInMemory: false
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
    if [ $namespace -eq $ns_name ]; then
      name="$(context.jq -r '.snapshots.roles['"$i"'].filterResult.name')"
      kubectl -n ${namespace} delete rolebindings ${name}
    fi
  done
}

function __main__() {
  for i in $(seq 0 "$(context::jq -r '(.snapshots.namespaces | length) - 1')"); do
    ns_name="$(context.jq -r '.snapshots.namespaces['"$i"'].filterResult.name')"
    if context::jq -e '.snapshots.namespaces['"$i"'].filterResult.hasLabel' ; then
      enable_rbac "$ns_name"
    else
      disable_rbac "$ns_name"
    fi
  done
}

hook::run "$@"