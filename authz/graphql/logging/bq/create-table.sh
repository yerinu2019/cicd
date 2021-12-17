#!/bin/bash

bq mk \
  -t \
  --expiration 3600 \
  --description "OPA decision log table" \
  monorepotest-323514:authz.decision_log \
  log_level:STRING,msg:STRING,log_time:STRING,decision_id:STRING,dest_ip:STRING,x_request_id:STRING,req_host:STRING, \
  req_path:STRING,req_time:STRING,src_ip:STRING,dest_principal:STRING,src_principal:STRING, \
  xfcc:STRING,path:STRING,allowed:BOOLEAN,cant_mutate:BOOLEAN,http_status:INTEGER, \
  timer_rego_external_resolve_ns:INT64,timer_rego_query_compile_ns:INT64,\
  timer_rego_query_eval_ns:INT64,timer_rego_query_eval_ns:INT64