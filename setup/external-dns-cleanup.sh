#!/bin/bash
echo "Delete cloud dns zone svc-yerinu-com"
gcloud dns managed-zones delete svc-yerinu-com

gcloud dns record-sets transaction start --zone "yerinu-com"
gcloud dns record-sets transaction remove ns-cloud-c{1..4}.googledomains.com. \
    --name "svc.yerinu.com." --ttl 300 --type NS --zone "yerinu-com"
gcloud dns record-sets transaction execute --zone "yerinu-com"
