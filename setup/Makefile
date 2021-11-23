.PHONY: all bin tools infra kubectl kustomize opa helm tkn argocd-cli gke-cicd external-dns external-dns-verify \
	cleanup gke-cicd-cleanup gke-cluster1-cleanup external-dns-cleanup external-dns-verify-cleanup \
	tekton authz-rego authz-acl authz-opa argocd argocd-first-password istioctl argo-events
all: infra listeners

bin:
	./setupbin.sh

tools: bin kustomize opa helm tkn argocd-cli kubectl istioctl

istioctl:
	./istioctl.sh

infra: gke-cicd external-dns tekton argocd argo-events gke-cluster-1

argo-events:
	./argo-events.sh
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
	./gke-cicd.sh

gke-cluster-1:
	./gke-cluster-1.sh

external-dns: gke-cicd
	./external-dns.sh
external-dns-verify: external-dns
	./external-dns-verify.sh
tekton:
	./tekton.sh
authz-rego: tekton
	./authz-rego.sh
authz-acl:
	./authz-acl.sh
authz-opa:
	./authz-opa.sh
gke-cicd-cleanup:
	./gke-cicd-cleanup.sh
gke-cluster1-cleanup:
	./gke-cluster1-cleanup.sh
external-dns-cleanup:
	./external-dns-cleanup.sh
external-dns-verify-cleanup:
	./external-dns-verify-cleanup.sh
cleanup: gke-cicd-cleanup gke-cluster1-cleanup
