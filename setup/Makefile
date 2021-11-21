.PHONY: all bin kubectl opa helm tkn argocd-cli gke-cicd external-dns external-dns-verify \
	cleanup gke-cicd-cleanup external-dns-cleanup external-dns-verify-cleanup \
	tekton authz-rego
all: opa tkn argocd-cli external-dns external-dns-verify tekton
bin:
	./setupbin.sh
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
external-dns: gke-cicd
	./external-dns.sh
external-dns-verify: external-dns
	./external-dns-verify.sh
tekton:
	./tekton.sh
authz-rego: tekton
	kubectl -f authz-rego/gitlab-listener.yaml
gke-cicd-cleanup:
	./gke-cicd-cleanup.sh
external-dns-cleanup:
	./external-dns-cleanup.sh
external-dns-verify-cleanup:
	./external-dns-verify-cleanup.sh
cleanup: external-dns-verify-cleanup external-dns-cleanup gke-cicd-cleanup
