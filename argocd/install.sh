#!/bin/bash
#echo "Enable minikube ingress"
#minikube addons enable ingress

kubectl config use-context gke_monorepotest-323514_us-west1-a_cicd

echo "Install helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd -n argocd argo/argocd --values values.yaml

echo "kubectl get ingress -n argocd"
kubectl get ingress -n argocd

echo "Add argocd ingress address in hosts file"
echo "echo '<argocd ingress address> argocd.minikube.local' | sudo tee -a /etc/hosts"
echo
echo "Open https://argocd.minikube.local/login using Browser"
echo "Default username is admin, password is the name of the pod. Get pod name using..."
echo "kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2"