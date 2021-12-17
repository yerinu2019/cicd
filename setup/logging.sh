#!/bin/bash
CURRENT_DIR=$(pwd)
cd ../authz/graphql/logging/bq
./create-table.sh
cd ${CURRENT_DIR}