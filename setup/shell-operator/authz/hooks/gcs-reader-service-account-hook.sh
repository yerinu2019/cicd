#!/bin/bash
# GCP service account for k8s service account
# If a k8s service account has label gcs-reader,
# make sure that the service account is bound to the GCP service account gcs_reader which has
# permission to read Google Cloud Storage
source /shell_lib.sh
source /common/k8s.sh

LABEL="gcs-reader"
function __config__() {
  k8s::service-account-filter $LABEL
}

function __main__() {
  k8s::bind-gcp-service-account "gcs-reader"
}

hook::run "$@"