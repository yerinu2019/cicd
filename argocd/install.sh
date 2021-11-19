#!/bin/bash
#echo "Enable minikube ingress"
#minikube addons enable ingress
./create-cluster.sh

kubectl config use-context gke_monorepotest-323514_us-west1-a_cicd

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Install argocd cli"
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && sudo chmod +x /usr/local/bin/argocd

echo "Expose argocd api server"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl -n argocd get all

echo "Initial admin secret"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d



#echo "kubectl get ingress -n argocd"
#kubectl get ingress -n argocd
#
#echo "Add argocd ingress address in hosts file"
#echo "echo '<argocd ingress address> argocd.minikube.local' | sudo tee -a /etc/hosts"
#echo
#echo "Open https://argocd.minikube.local/login using Browser"
#echo "Default username is admin, password is the name of the pod. Get pod name using..."
#echo "kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2"