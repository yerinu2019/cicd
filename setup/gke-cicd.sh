#!/bin/bash
CLUSTER_NAME="cicd"
echo "Create GKE cicd"
source ../bash/gke-func.sh
create-gke $CLUSTER_NAME

gcloud container clusters update $CLUSTER_NAME \
    --update-addons ConfigConnector=ENABLED

kubectl apply -f gcp-service-account.yaml

export GCP_PROJECT_ID=`gcloud config get-value project`
export GCP_SERVICE_ACCOUNT="cicd-sa"
export K8S_NAMESPACE="default"
export K8S_SERVICE_ACCOUNT="cicd-sa"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member "serviceAccount:${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/storage.objectAdmin"

gcloud iam service-accounts add-iam-policy-binding ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"

kubectl annotate serviceaccount \
    --namespace ${K8S_NAMESPACE} ${K8S_SERVICE_ACCOUNT} \
    iam.gke.io/gcp-service-account=${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com
