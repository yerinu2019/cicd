#!/bin/bash
echo "Deleting cicd cluster..."
gcloud container clusters delete cicd --zone us-central1-a -q
