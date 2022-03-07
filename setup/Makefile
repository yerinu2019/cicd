.PHONY: all bin tools infra kubectl kustomize opa helm tkn argocd-cli gke-cicd external-dns external-dns-verify \
	cleanup gke-cicd-cleanup gke-cluster1-cleanup external-dns-cleanup external-dns-verify-cleanup \
	tekton argocd argocd-first-password istioctl argo-events \
	authz authz-rego authz-operator authz-example gcp-api anthos1 anthos1-cleanup logging

all: infra listeners

bin:
	./setupbin.sh

tools: bin kustomize opa helm tkn argocd-cli kubectl istioctl operator-sdk

istioctl:
	./istioctl.sh

infra: gcp-api gke-cicd external-dns argocd gke-cluster1

gcp-api:
	./gcp-api.sh

authz: gke-cicd external-dns argocd gke-cluster1 logging authz-operator

logging:
	./logging.sh

authz-example:
	./authz-example.sh
authz-operator:
	./authz-operator.sh
authz-rego: tekton
	./authz-rego.sh
argo-events:
	./argo-events.sh

argo-workflow:
	./argo-workflow.sh

argocd:
	./argocd-server.sh

argocd-first-password:
	./argocd/first-password.sh

apps: authz-rego authz-acl 

kustomize:
	curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

kubectl:
	./kubectl.sh

opa: bin
	./opa.sh

helm: bin
	./helm.sh

tkn: bin
	./tkn.sh

argocd-cli: bin
	./argocd-cli.sh

gke-cicd: gcp-api
	./gke-create.sh cicd

gke-cicd-cleanup:
	./gke-delete.sh cicd

gke-cluster1:
	./gke-app-cluster.sh cluster1
gke-cluster1-cleanup:
	./gke-delete.sh cluster1

anthos1:
	./anthos-create-cluster.sh anthos1

anthos1-cleanup:
	./gke-anthos-delete.sh anthos1 us-central1-a

external-dns: 
	./external-dns.sh
external-dns-verify: external-dns
	./external-dns-verify.sh
tekton:
	./tekton.sh
external-dns-cleanup:
	./external-dns-cleanup.sh
external-dns-verify-cleanup:
	./external-dns-verify-cleanup.sh
cleanup: gke-cicd-cleanup gke-cluster1-cleanup

gke-zookeeper:
	./gke-app-cluster.sh zookeeper 3
gke-zookeeper-cleanup:
	./gke-delete.sh zookeeper

zookeeper: gke-zookeeper
	kubectl apply -f ./zookeeper/zookeper.yaml