#!/bin/bash
kubectl apply -f external-dns-verify.yaml

gcloud dns record-sets list \
    --zone "svc-yerinu-com" \
    --name "nginx.svc.yerinu.com."

dig +short @ns-cloud-c1.googledomains.com. nginx.svc.yerinu.com.

curl nginx.svc.yerinu.com

gcloud dns record-sets list \
    --zone "svc-yerinu-com" \
    --name "via-ingress.svc.yerinu.com."

dig +short @ns-cloud-c1.googledomains.com. via-ingress.svc.yerinu.com.

curl via-ingress.svc.yerinu.com