#!/bin/bash
source ../bash/gke-func.sh
create-gke "monorepotest-323514" "us-west1-a" "us-west1" "cicd"

./install.sh