#!/bin/bash
kubectl apply -k argo-events
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/master/manifests/install-validating-webhook.yaml

#TODO: Disable argo events webhook. argo event is installed on all gke clusters. Automatic external dns
# might have problems if multiple argo event webhook service is exposed to cloud dns entries using
# the same host name.