#!/bin/bash
# Install sidecars and service accounts for authz opa istio enabled pods
source /shell_lib.sh
source /common/authz.sh

function __config__() {
  cat <<EOF
  configVersion: v1
  onStartup: 1
EOF
}

function __main__() {
  #authz::reconcile
  echo "Don't execute startup hook"
}

hook::run "$@"