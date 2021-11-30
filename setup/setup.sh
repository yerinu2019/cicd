#!/bin/bash
if [ ! -d "$HOME/bin" ]; then
  mkdir $HOME/bin
  export PATH=$HOME/bin:$PATH
fi

echo "Install opa"
curl -L -o $HOME/bin/opa https://github.com/open-policy-agent/opa/releases/download/v0.34.2/opa_linux_amd64
chmod 755 $HOME/bin/opa

echo "Install helm 3"
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

echo "Install tekton cli"
sudo apt update;sudo apt install -y gnupg
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main"|sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list
sudo apt update && sudo apt install -y tektoncd-cli

echo "Install argocd cli"
curl -sSL -o $HOME/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x $HOME/bin/argocd


echo "Create GKE cicd"
source ../bash/gke-func.sh
create-gke "monorepotest-323514" "us-central1-a" "us-central1" "cicd"

echo "Install external DNS"
helm repo add bitnami https://charts.bitnami.com/bitnami



echo "Install tekton in cicd GKE"
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml

echo "Configure tekton rbac"
kubectl apply -f tekton-rbac.yaml

echo "Configure authz gitlab listener"
kubectl apply -f ../tekton/authz/gitlab-listener.yaml

echo "Install argocd in cicd GKE"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Expose argocd api server"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

echo "Check argocd server external IP address"
kubectl -n argocd get all

echo "Check initial argocd admin secret"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

echo "Install authz policy"
kubectl apply -k ../argocd/applications/authz/base

echo "Install ingress nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml
echo "Configure ingress to authz and opa-envoy-plugin gitlab listener"
kubectl apply -f gke-ingress.yaml