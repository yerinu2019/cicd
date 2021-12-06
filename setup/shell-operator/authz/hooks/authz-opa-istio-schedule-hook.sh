#!/bin/bash
# Install sidecars and service accounts for authz opa istio enabled pods
source /shell_lib.sh
source /common/authz.sh

function __config__() {
  cat <<EOF
  configVersion: v1
  schedule:
    - name: "reconcile every 1 min"
      crontab: "*/1 * * * *"
EOF
}

function __main__() {
  authz::reconcile
}

hook::run "$@"