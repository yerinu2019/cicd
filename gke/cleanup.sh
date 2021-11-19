#!/bin/bash
source ../bash/gke-func.sh
delete-gke "cicd" "us-west1-a"
delete-gke "opa" "us-west1-a"
