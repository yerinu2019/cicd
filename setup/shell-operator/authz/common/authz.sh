#!/bin/bash
source /common/k8s.sh

function authz::reconcile() {
  items="$(kubectl get deployment -l authz-opa-istio=enabled -A -o json | jq  -c '.items[] | {namespace: .metadata.namespace, name: .metadata.name, selector: .spec.selector, opaconfig: .metadata.annotations.opaconfig}')"
  echo "Items: ${items}"
  for item in ${items}; do
    echo "Item: ${item}"
    NAMESPACE=$(echo $item | jq -r '.namespace')
    DEPLOYMENT_NAME=$(echo $item | jq -r '.name')
    POD_SELECTOR=$(echo $item | jq -r '.selector')
    POD_SELECTOR_LABELS=$(echo "${POD_SELECTOR}" | jq -c '.matchLabels | to_entries' | jq -r 'map("\(.key)=\(.value|tostring)")|join(",")')
    POD_CONTAINERS=$(kubectl -n "${NAMESPACE}" get po -l "${POD_SELECTOR_LABELS}" -o json | jq -r '.items[].spec.containers[].name' | jq --raw-input --slurp 'split("\n") | del(.[] | select(. == ""))')
    echo "${POD_CONTAINERS}"

    OPA_CONFIG_NAME=$(echo $item | jq -r '.opaconfig')
    if [[ $(echo "${POD_CONTAINERS}" | jq 'any(.[] == "opa-istio"; .)') ]]; then
      echo "opa sidecar is found"
      # ensure service account has gcs reader permission
      SERVICE_ACCOUNT_NAME=${DEPLOYMENT_NAME}
      authz::configure-service-account "${NAMESPACE}" "${SERVICE_ACCOUNT_NAME}"
      authz::sync-rego-configmap "${NAMESPACE}" "${OPA_CONFIG_NAME}"
      authz::sync-inject-configmap "${NAMESPACE}" "${OPA_CONFIG_NAME}"
    else
      echo "injecting opa sidecar"
      authz::inject-sidecars "${NAMESPACE}" "${OPA_CONFIG_NAME}"
      kubectl -n "${NAMESPACE}" rollout restart deployment "${DEPLOYMENT_NAME}"
    fi
  done
}

function authz::inject-sidecars() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: authz::inject-sidecar <namespace> <opa config name>"
      exit 255
  fi

  NAMESPACE=$1
  OPA_CONFIG_NAME=$2

  if [[ -z "${OPA_CONFIG_NAME}" ]]; then
    return
  fi

  authz::sync-rbac "${NAMESPACE}" "${OPA_CONFIG_NAME}"
  authz::sync-rego-configmap "${NAMESPACE}" "${OPA_CONFIG_NAME}"
  authz::sync-inject-configmap "${NAMESPACE}" "${OPA_CONFIG_NAME}"

  # ensure namespace is istio enabled
  k8s::ensure_istio_enabled "$NAMESPACE"

  kubectl apply -f /common/opa/opa-envoy-filter.yaml
  kubectl apply -f /common/opa/opa-istio.yaml
  kubectl -n "${NAMESPACE}" apply -f /common/opa/gcs-egress.yaml

  # associate service account
  DEPLOYMENT_NAME="$(context::jq -r '.snapshots.deployments['"$i"'].filterResult.name')"
  SERVICE_ACCOUNT_NAME=$DEPLOYMENT_NAME

  authz::configure-service-account "${NAMESPACE}" "${SERVICE_ACCOUNT_NAME}"
  kubectl -n "${NAMESPACE}" rollout restart deployment "${DEPLOYMENT_NAME}"
}

function authz::configure-service-account() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: authz::configure-service-account <namespace> <service account name>"
      exit 255
  fi
  NAMESPACE=$1
  SERVICE_ACCOUNT_NAME=$2
  # associate service account
  SERVICE_ACCOUNT_NAME=$DEPLOYMENT_NAME
  k8s::ensure_service_account "$NAMESPACE" "$SERVICE_ACCOUNT_NAME"
  kubectl -n "${NAMESPACE}" set sa deployment "${DEPLOYMENT_NAME}" "${SERVICE_ACCOUNT_NAME}"

  # make service account can read gcs rego bundle
  GCP_SERVICE_ACCOUNT="gcs-reader"
  gcp::create-gcp-service-account ${GCP_SERVICE_ACCOUNT}
  gcp::bind-role ${GCP_SERVICE_ACCOUNT} "roles/storage.objectViewer"
  gcp::bind_gcp_service_account ${GCP_SERVICE_ACCOUNT} "${SERVICE_ACCOUNT_NAME}" "${NAMESPACE}"
}

function authz::authz-opa-istio-deployment-filter() {
  SNAPSHOT_NAME="deployments"
  LABEL="authz-opa-istio"
  LABEL_VALUE="enabled"
  RESOURCE_TYPE="Deployment"
  k8s::resource-label-filter "apps" "v1" $RESOURCE_TYPE $LABEL $LABEL_VALUE $SNAPSHOT_NAME
}

function authz::handle-authz-opa-istio-enabled-deployment() {
  SNAPSHOT_NAME="deployments"
  for i in $(seq 0 "$(context::jq -r '(.snapshots.deployments | length) - 1')"); do
    LABEL_MATCHED=$(context::jq -r '.snapshots.deployments['"$i"'].filterResult.labelMatched')
    NAMESPACE=$(context::jq -r '.snapshots.deployments['"$i"'].filterResult.namespace')
    NAME=$(context::jq -r '.snapshots.deployments['"$i"'].filterResult.name')
    echo "Deployment ${NAME}/${NAMESPACE}, LABEL_MATCHED: ${LABEL_MATCHED}"
    if [[ ${LABEL_MATCHED} == true ]]; then
      OPA_CONFIG_NAME=$(context::jq -r '.snapshots.deployments['"$i"'].filterResult.opaconfig')
      authz::inject-sidecars "${NAMESPACE}" "${OPA_CONFIG_NAME}"
    fi
  done
}



function authz::sync-rbac() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: authz::setup-rbac <namespace> <opa-confog-name"
      exit 255
  fi

  NAMESPACE=$1
  OPA_CONFIG_NAME=$2

  if [[ -z "${OPA_CONFIG_NAME}" ]]; then
    return
  fi
  OPA_CONFIG=$(kubectl -n "${NAMESPACE}" --ignore-not-found=true get opaconfig "${OPA_CONFIG_NAME}" -o json)

  if [[ -z "${OPA_CONFIG}" ]]; then
    return
  fi

  POLICY_CRD_NAME=$(echo "$OPA_CONFIG" | jq -r '.spec."policy-crd-name"')
  POLICY_CRD_GROUP=$(echo "$OPA_CONFIG" | jq -r '.spec."policy-crd-group"')
  POLICY_CRD_VERSION=$(echo "$OPA_CONFIG" | jq -r '.spec."policy-crd-version"')
  POLICY_MONITOR_NAME=${POLICY_CRD_NAME}-monitor
  OPA_VIEWER_NAME="opa-viewer"
  CONFIGMAP_MODIFIER_NAME="opa-configmap-modifier"

  cat <<EOF | kubectl apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${POLICY_MONITOR_NAME}
rules:
  - apiGroups: ["${POLICY_CRD_GROUP}"]
    resources: ["${POLICY_CRD}"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${POLICY_MONITOR_NAME}-${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: ${POLICY_MONITOR_NAME}
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: Group
    name: system:serviceaccounts:${NAMESPACE}
    apiGroup: rbac.authorization.k8s.io
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${OPA_VIEWER_NAME}-${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: Group
    name: system:serviceaccounts:${NAMESPACE}
    apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${CONFIGMAP_MODIFIER_NAME}
  namespace: ${NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${CONFIGMAP_MODIFIER_NAME}
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

function authz::sync-inject-configmap() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: authz::create-inject-configmap <namespace> <opa-config-name>"
      exit 255
  fi

  NAMESPACE=$1
  OPA_CONFIG_NAME=$2

  if [[ -z "${OPA_CONFIG_NAME}" ]]; then
    return
  fi
  OPA_CONFIG=$(kubectl -n "${NAMESPACE}" --ignore-not-found=true get opaconfig "${OPA_CONFIG_NAME}" -o json)

  if [[ -z "${OPA_CONFIG}" ]]; then
    return
  fi

  KUBE_MGMT_REPLICATE=$(echo "$OPA_CONFIG" | jq -r '.spec."kube-mgmt-replicate"')

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: inject-policy
  namespace: opa-istio
data:
  inject.rego: |
    package istio

    inject = {
      "apiVersion": "admission.k8s.io/v1",
      "kind": "AdmissionReview",
      "response": {
        "allowed": true,
        "uid" : input.request.uid,
        "patchType": "JSONPatch",
        "patch": base64.encode(json.marshal(patch)),
      },
    }

    patch = [{
      "op": "add",
      "path": "/spec/containers/-",
      "value": opa_container,
    }, {
      "op": "add",
      "path": "/spec/containers/-",
      "value": kubemgmt_container,
    }, {
      "op": "add",
      "path": "/spec/volumes/-",
      "value": rego_volume,
    }]

    kubemgmt_container = {
      "name": "kube-mgmt",
      "image": "openpolicyagent/kube-mgmt:latest",
      "args": [
          "--policies=${NAMESPACE}",
          "--enable-data",
          "--replicate=${KUBE_MGMT_REPLICATE}"
      ],
    }

    opa_container = {
      "image": "yerinu2019/opa-envoy-plugin:latest",
      "name": "opa-istio",
      "args": [
        "run",
        "--server",
        "--config-file=/config/config.yaml",
        "--addr=localhost:8181",
        "--log-level=error",
        "--log-format=json-pretty",
        "--set=decision_logs.console=true",
        "--diagnostic-addr=0.0.0.0:8282",
      ],
      "volumeMounts": [{
        "mountPath": "/config",
        "name": "rego-config",
      }],
      "readinessProbe": {
        "httpGet": {
          "path": "/health?plugins",
          "port": 8282,
        },
      },
      "livenessProbe": {
        "httpGet": {
          "path": "/health?plugins",
          "port": 8282,
        },
      }
    }

    rego_volume = {
      "name": "rego-config",
      "configMap": {"name": "rego-config"},
    }
EOF
}

function authz::sync-rego-configmap() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: authz::create-rego-configmap <namespace> <opa-config-name>"
      exit 255
  fi

  NAMESPACE=$1
  OPA_CONFIG_NAME=$2

  if [[ -z "${OPA_CONFIG_NAME}" ]]; then
    return
  fi
  OPA_CONFIG=$(kubectl -n "${NAMESPACE}" --ignore-not-found=true get opaconfig "${OPA_CONFIG_NAME}" -o json)

  if [[ -z "${OPA_CONFIG}" ]]; then
    return
  fi
  REGO_BUNDLE_URL=$(echo "$OPA_CONFIG" | jq -r '.spec."rego-bundle-url"')
  REGO_BUNDLE_FILE=$(echo "$OPA_CONFIG" | jq -r '.spec."rego-bundle-file"')

  cat <<EOF | kubectl -n "${NAMESPACE}" apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: rego-config
data:
  config.yaml: |
    services:
      - name: gcs
        url: ${REGO_BUNDLE_URL}
        credentials:
          gcp_metadata:
            scopes:
              - https://www.googleapis.com/auth/devstorage.read_only
    bundles:
      istio/authz:
        service: gcs
        # NOTE ?alt=media is required
        resource: ${REGO_BUNDLE_FILE}?alt=media'
        persist: true
    plugins:
      envoy_ext_authz_grpc:
        addr: :9191
        path: istio/authz/allow
    decision_logs:
      console: true
EOF
}

