#!/bin/bash
COUNT=$1
for i in $(seq 1 1 $COUNT)
do
  client_num=$((1 + $RANDOM %2))
  api_num=$((1 + $RANDOM %2))

  ./mutate.sh clientns client${client_num} api${api_num}.api-istio &
done