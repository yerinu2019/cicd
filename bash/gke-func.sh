#!/bin/bash

function create-gke() {
  if [ "$#" -ne 4 ]; then
      echo "Usage: create-gke <project-id> <zone> <region> <cluster-name>"
      exit 1
  fi

  gcloud config set project $1
  gcloud config set compute/zone $2
  gcloud config set compute/region $3

  GKE=`gcloud container clusters list | grep $4`
  echo $GKE
  if [[ -z "${GKE}" ]]; then
    echo "Create GKE $4"
    gcloud container clusters create $4 --num-nodes=1
    gcloud container clusters get-credentials $4
  else
    echo "GKE $4 exists."
  fi
}

function delete-gke() {
  if [ "$#" -ne 2 ]; then
      echo "Usage: delete-gke <cluster-name> <zone>"
      exit 1
  fi

  GKE=`gcloud container clusters list | grep $1`
  echo $GKE

  if [[ -z "${GKE}" ]]; then
    echo "GKE $1 does not exists."
  else
    gcloud container clusters delete $1 --zone $2 -q
  fi
}