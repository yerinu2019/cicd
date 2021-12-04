#!/bin/bash
POD=`kubectl -n $1 get pod -l app=$2 -o jsonpath='{.items..metadata.name}'`
echo POD: $POD
kubectl -n $1 exec $POD -- curl -i -g -sS \
-X POST \
-H "Content-Type: application/json" \
-d '{"query":"# some comment lines\nmutation createIndexes {\n  user1: createIndex(\n    keyspaceName:\"'$KEYSPACE_NAME'\",\n    tableName:\"'$TABLE_NAME'\",\n    columnName:\"favorite_books\",\n    indexName:\"fav_books_idx\",\n    indexKind: VALUES\n  )\n  user2:createIndex(\n    keyspaceName:\"'$KEYSPACE_NAME'\",\n    tableName:\"'$TABLE_NAME'\",\n    columnName:\"top_three_tv_shows\",\n    indexName:\"tv_idx\",\n    indexKind: VALUES\n  )\n  user3:createIndex(\n    keyspaceName:\"'$KEYSPACE_NAME'\",\n    tableName:\"'$TABLE_NAME'\",\n    columnName:\"evaluations\",\n    indexName:\"evalv_idx\",\n    indexKind: VALUES\n  )\n   user4:createIndex(\n    keyspaceName:\"'$KEYSPACE_NAME'\",\n    tableName:\"'$TABLE_NAME'\",\n    columnName:\"evaluations\",\n    indexName:\"evalk_idx\",\n    indexKind: KEYS\n  )\n   user5:createIndex(\n    keyspaceName:\"'$KEYSPACE_NAME'\",\n    tableName:\"'$TABLE_NAME'\",\n    columnName:\"evaluations\",\n    indexName:\"evale_idx\",\n    indexKind: ENTRIES\n  )\n    users6: createIndex(\n    keyspaceName:\"'$KEYSPACE_NAME'\",\n    tableName:\"'$TABLE_NAME'\",\n    columnName:\"current_country\",\n    indexName:\"country_idx\"\n  )\n}","variables":{}}' \
$3
