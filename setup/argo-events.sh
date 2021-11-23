#!/bin/bash
kubectl apply -k argo-events
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/master/manifests/install-validating-webhook.yaml