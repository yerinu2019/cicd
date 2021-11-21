.PHONY: all bin kubectl opa helm tkn argocd-cli gke-cicd external-dns external-dns-verify \
	cleanup gke-cicd-cleanup external-dns-cleanup
all: opa tkn argocd-cli external-dns external-dns-verify
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
gke-cicd: kubectl
	./gke-cicd.sh
external-dns: gke-cicd
	./external-dns.sh
external-dns-verify: external-dns
	./external-dns-verify.sh
gke-cicd-cleanup:
	./gke-cicd-cleanup.sh
external-dns-cleanup:
	./external-dns-cleanup.sh
cleanup: external-dns-cleanup gke-cicd-cleanup
