#!/bin/bash
CURRENT_DIR=$(PWD)
bq mk \
  --table \
  --expiration 3600 \
  --description "OPA decision log table" \
  monorepotest-323514:authz.decision_log \
  ${CURRENT_DIR}/schema.json