#!/bin/bash
echl "Deleting cicd cluster..."
gcloud container clusters delete cicd --zone us-west1-a -q
