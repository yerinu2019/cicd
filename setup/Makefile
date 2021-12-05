.PHONY: all bin tools infra kubectl kustomize opa helm tkn argocd-cli gke-cicd external-dns external-dns-verify \
	cleanup gke-cicd-cleanup gke-cluster1-cleanup external-dns-cleanup external-dns-verify-cleanup \
	tekton argocd argocd-first-password istioctl argo-events \
	authz authz-rego authz-opa authz-operator authz-example
all: infra listeners

bin:
	./setupbin.sh

tools: bin kustomize opa helm tkn argocd-cli kubectl istioctl operator-sdk

istioctl:
	./istioctl.sh

infra: gke-cicd external-dns argocd gke-cluster-1

#authz: gke-cicd external-dns argocd gke-cluster-1 authz-operator authz-opa authz-acl authz-client
authz: gke-cicd external-dns argocd gke-cluster-1 authz-operator

authz-example:
	./authz-example.sh
authz-operator:
	./authz-operator.sh
authz-rego: tekton
	./authz-rego.sh
authz-opa:
	./authz-opa.sh

argo-events:
	./argo-events.sh

argo-workflow:
	./argo-workflow.sh

argocd:
	./argocd-server.sh

argocd-first-password:
	./argocd/first-password.sh

apps: authz-rego authz-acl authz-opa

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
gke-cicd:
	./gke-create.sh cicd
gke-cicd-cleanup:
	./gke-delete.sh cicd

gke-cluster-1:
	./gke-app-cluster.sh cluster1
gke-cluster1-cleanup:
	./gke-delete.sh cluster1

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
