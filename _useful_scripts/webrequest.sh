#!/bin/bash

curl https://d382w9uy20fydd.cloudfront.net/v1/customer \
  -X POST \
  -H "Content-Type: application/json" \
  --data-binary @- <<-EOF

    {
      "id": "00001",
      "name": "00001",
      "gender": "00001"
    }

EOF
