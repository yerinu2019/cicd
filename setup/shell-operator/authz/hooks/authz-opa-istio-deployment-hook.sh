#!/bin/bash
# Install sidecars and service accounts for authz opa istio enabled pods
source /shell_lib.sh
source /common/authz.sh

function __config__() {
  authz::authz-opa-istio-deployment-filter
}

function __main__() {
  authz::handle-authz-opa-istio-enabled-deployment
}

hook::run "$@"