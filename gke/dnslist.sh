#!/bin/bash

gcloud dns record-sets list \
 --project acme-quality-team \
 --zone acme-test \
 --filter "type=NS OR type=SOA" \
 --format json