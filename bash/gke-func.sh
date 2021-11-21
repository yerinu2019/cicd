#!/bin/bash

function create-gke() {
  MY_SCOPES=$(IFS=,; echo "${SCOPES[*]}")               # scope list (command seperated)
  MY_CLUSTER_NAME=${1:-"test-cluster"}                  # gke cluster name
  MY_ZONE=${2:-"us-central1-1"}                         # default zone if not set
  MY_REGION=${3:-"us-central1"}                         # default region if not set
  MY_PROJECT=${4:-"$(gcloud config get-value project)"} # default project if not set

  # desired scopes - default + CloudDNS access
    SCOPES=("https://www.googleapis.com/auth/devstorage.read_only"
            "https://www.googleapis.com/auth/logging.write"
            "https://www.googleapis.com/auth/monitoring"
            "https://www.googleapis.com/auth/servicecontrol"
            "https://www.googleapis.com/auth/service.management.readonly"
            "https://www.googleapis.com/auth/trace.append"
            "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
    )

  gcloud config set project $MY_PROJECT
  gcloud config set compute/zone $MY_ZONE
  gcloud config set compute/region $MY_REGION

  GKE=`gcloud container clusters list | grep $MY_CLUSTER_NAME`
  echo $GKE
  if [[ -z "${GKE}" ]]; then
    echo "Create GKE $MY_CLUSTER_NAME"
    # Create GKE Cluster
    gcloud container clusters create \
      --num-nodes 1 \
      --scopes $MY_SCOPES \
      --workload-pool=$MY_PROJECT.svc.id.goog \
      $MY_CLUSTER_NAME

    set-myself-admin $MY_CLUSTER_NAME
  else
    echo "GKE $MY_CLUSTER_NAME exists."
  fi
}

function delete-gke() {
  MY_CLUSTER_NAME=${1:-"test-cluster"}                  # gke cluster name
  MY_ZONE=${2:-"us-central1-a"}                         # default zone if not set

  GKE=`gcloud container clusters list | grep $MY_CLUSTER_NAME`
  echo $GKE

  if [[ -z "${GKE}" ]]; then
    echo "GKE $MY_CLUSTER_NAME does not exists."
  else
    gcloud container clusters delete $MY_CLUSTER_NAME --zone $MY_ZONE -q
  fi
}

function set-myself-admin() {
  MY_CLUSTER_NAME=${1:-"test-cluster"}                  # gke cluster name
  gcloud container clusters get-credentials $MY_CLUSTER_NAME
  kubectl create clusterrolebinding cluster-admin-me \
      --clusterrole=cluster-admin --user="$(gcloud config get-value account)"
}