#!/bin/bash
echo "Create external DNS zone"
gcloud dns managed-zones create "svc-yerinu-com" \
    --dns-name "svc.yerinu.com." \
    --description "Automatically managed zone by ExternalDNS"

echo "Tell the parent zone where to find the DNS records for this zone by adding the corresponding NS records there."
gcloud dns record-sets transaction start --zone "yerinu-com"
gcloud dns record-sets transaction add ns-cloud-c{1..4}.googledomains.com. \
    --name "svc.yerinu.com." --ttl 300 --type NS --zone "yerinu-com"
gcloud dns record-sets transaction execute --zone "yerinu-com"

kubectl apply -f external-dns.yaml

