#!/bin/bash
A=$(curl -X POST localhost:8080/unicorn -H "Content-Type: application/json" -d '{"name":"healthcheck"}' | jq "{a:.mysql|tostring,b:.mongodb|tostring}|.a+.b" -r)

if [ "$A" == "truetrue" ]; then
  exit 0
fi

exit 1
