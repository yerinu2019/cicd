#!/bin/bash
DIR=$(pwd)
CHECK=$(bq ls authz | grep decision_log)
if [[ -z $"$CHECK" ]]; then
  bq mk \
    --table \
    --expiration 3600 \
    --description "OPA decision log table" \
    monorepotest-323514:authz.decision_log \
    ${DIR}/schema.json
else
  bq update monorepotest-323514:authz.decision_log ${DIR}/schema.json
fi


cd ../adapter
./make.sh