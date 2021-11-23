#!/bin/bash
kubectl -n api-istio apply -f authz-opa/opa-envoy-filter.yaml
kubectl -n api-istio apply -f authz-opa/opa-rbac.yaml
kubectl -n api-istio apply -f authz-opa/opa-istio.yaml
kubectl -n api-istio apply -f authz-opa/gcs-egress.yaml
kubectl -n api-istio apply -f authz-opa/rego-configmap.yaml
