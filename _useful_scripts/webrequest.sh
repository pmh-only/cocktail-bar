#!/bin/bash

curl https://dfsdfsdfds.free.beeceptor.com \
  -X POST \
  -H "Content-Type: application/json" \
  -d "$(cat <<-EOF

    {
      "hello" : "world!"
    }

    EOF )"
