#!/bin/bash

function create-gke() {
  # desired scopes - default + CloudDNS access
  SCOPES=("https://www.googleapis.com/auth/devstorage.read_write"
          "https://www.googleapis.com/auth/cloud-platform"
          "https://www.googleapis.com/auth/cloudplatformprojects"
          "https://www.googleapis.com/auth/logging.write"
          "https://www.googleapis.com/auth/monitoring"
          "https://www.googleapis.com/auth/servicecontrol"
          "https://www.googleapis.com/auth/service.management.readonly"
          "https://www.googleapis.com/auth/trace.append"
          "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
  )

  MY_SCOPES=$(IFS=,; echo "${SCOPES[*]}")               # scope list (command seperated)
  MY_CLUSTER_NAME=${1:-"test-cluster"}                  # gke cluster name
  MY_ZONE=${2:-"us-central1-a"}                         # default zone if not set
  MY_REGION=${3:-"us-central1"}                         # default region if not set
  MY_PROJECT=${4:-"$(gcloud config get-value project)"} # default project if not set
  NUM_NODES=${5:-"1"}
  CPU=${6:-"2"}
  MEM=${7:-"8"}

  gcloud config set project $MY_PROJECT
  gcloud config set compute/zone $MY_ZONE
  gcloud config set compute/region $MY_REGION

  GKE=`gcloud container clusters list | grep $MY_CLUSTER_NAME`
  echo $GKE
  if [[ -z "${GKE}" ]]; then
    echo "Create GKE $MY_CLUSTER_NAME"
    # Create GKE Cluster
    gcloud container clusters create \
          --num-nodes ${NUM_NODES} \
          --scopes $MY_SCOPES \
          --workload-pool=$MY_PROJECT.svc.id.goog \
          --enable-vertical-pod-autoscaling \
          --enable-autoprovisioning \
          --max-memory ${MEM} \
          --max-cpu ${CPU} \
          $MY_CLUSTER_NAME

    set-myself-admin $MY_CLUSTER_NAME $MY_ZONE
  else
    echo "GKE $MY_CLUSTER_NAME exists."
  fi
#  gcloud container clusters update $MY_CLUSTER_NAME \
#      --update-addons ConfigConnector=ENABLED
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

function switch-gke() {
  if [[ "$#" -lt 1 ]]; then
      echo "Usage: switch-gke <gke cluster name> [<zone>]"
      exit 255
  fi
  MY_ZONE=${2:-"us-central1-a"}                         # default zone if not set
  gcloud container clusters get-credentials $1 --zone $MY_ZONE -q
}

function current-gke-cluster() {
  IFS='_' read -ra ARR <<< `kubectl config current-context`
  if [[ ${ARR[0]} -eq "gke" ]]; then
    __=${ARR[3]}
  else
    __=""
  fi
}

function set-myself-admin() {
  MY_CLUSTER_NAME=${1:-"test-cluster"}                  # gke cluster name
  gcloud container clusters get-credentials $MY_CLUSTER_NAME
  kubectl create clusterrolebinding cluster-admin-me \
      --clusterrole=cluster-admin --user="$(gcloud config get-value account)"
}

function create-gcp-service-account() {
  if [[ "$#" -ne 1 ]]; then
      echo "Usage: create-gcp-service-account <gcp service account>"
      exit -1
  fi
  GSA=$1
  CHECK=`gcloud iam service-accounts list | grep ${GSA}@`
  echo "Check Google Service Account Result for ${GSA}@: ${CHECK}"
  if [[ -z "${CHECK}" ]]; then
    gcloud iam service-accounts create $GSA
  else
    echo "GSA $GSA exists."
  fi
}

function bind-role() {
  if [[ "$#" -ne 2 ]]; then
      echo "Usage: bind-role <gcp service account> <role>"
      exit -1
  fi
  GCP_PROJECT_ID=`gcloud config get-value project`
  GCP_SERVICE_ACCOUNT=$1
  ROLE=$2
  gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
      --member "serviceAccount:${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
      --role $ROLE
}

function use-workload-identity() {
  if [[ "$#" -ne 3 ]]; then
      echo "Usage: use-workload-identity <gcp service account> <k8s namespace> <k8s service account>"
      exit -1
  fi
  GCP_PROJECT_ID=`gcloud config get-value project`
  GCP_SERVICE_ACCOUNT=$1
  K8S_NAMESPACE=$2
  K8S_SERVICE_ACCOUNT=$3

  gcloud iam service-accounts add-iam-policy-binding ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"

  CHECK=`kubectl get ns ${K8S_NAMESPACE} -o jsonpath="{.metadata.name}"`
  if [[ -z "${CHECK}" ]]; then
    kubectl create ns ${K8S_NAMESPACE}
  fi

  CHECK=`kubectl -n ${K8S_NAMESPACE} get sa | grep ${K8S_SERVICE_ACCOUNT}`
  if [[ -z "${CHECK}" ]]; then
    kubectl -n ${K8S_NAMESPACE} create sa ${K8S_SERVICE_ACCOUNT}
  fi

  CHECK=`kubectl -n ${K8S_NAMESPACE} describe sa ${K8S_SERVICE_ACCOUNT} | grep iam.gke.io/gcp-service-account`
  if [[ -z "${CHECK}" ]]; then
    kubectl annotate sa \
          -n ${K8S_NAMESPACE} ${K8S_SERVICE_ACCOUNT} \
          iam.gke.io/gcp-service-account=${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com
  fi
}