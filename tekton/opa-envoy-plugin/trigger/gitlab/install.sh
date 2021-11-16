#!/bin/bash
kubectl apply -f ../rbac.yaml
kubectl apply -f gitlab-listener.yaml
