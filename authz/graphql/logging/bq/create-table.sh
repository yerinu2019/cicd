#!/bin/bash
DIR=$(pwd)
bq mk \
  --table \
  --expiration 3600 \
  --description "OPA decision log table" \
  monorepotest-323514:authz.decision_log \
  ${DIR}/schema.json