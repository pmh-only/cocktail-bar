#!/bin/sh
wget $(curl https://api.github.com/repos/ekristen/aws-nuke/releases/latest | jq '.assets[]|select(.name|endswith("linux-amd64.tar.gz")).browser_download_url' -r) -O- | tar zxvf -

# nuke -q --force --no-alias-check --no-dry-run
