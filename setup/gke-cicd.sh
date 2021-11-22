#!/bin/bash
echo "Create GKE cicd"
source ../bash/gke-func.sh
create-gke "cicd"
kubectl apply -f gcp-service-account.yaml

GCP_PROJECT_ID=`gcloud config get-value project`
GCP_SERVICE_ACCOUNT="cicd-sa"
K8S_NAMESPACE="default"
K8S_SERVICE_ACCOUNT="cicd-sa"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member "serviceAccount:${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
    --role "ROLE_NAME"

gcloud iam service-accounts add-iam-policy-binding ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"

kubectl annotate serviceaccount \
    --namespace ${K8S_NAMESPACE} ${K8S_SERVICE_ACCOUNT} \
    iam.gke.io/gcp-service-account=${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com
