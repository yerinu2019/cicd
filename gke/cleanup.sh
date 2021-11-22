#!/bin/bash
source ../bash/gke-func.sh
delete-gke "cicd" "us-central1-a" &
delete-gke "opa" "us-central1-a"
