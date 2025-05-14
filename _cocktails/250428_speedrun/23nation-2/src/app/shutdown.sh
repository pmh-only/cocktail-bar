#!/bin/sh

aws s3 cp /home/ec2-user/app/log/app.log "s3://wsi-logs-pmhn/accesslog-backup/shutdown/$(date +%Y/%m/%d/%H/%M)/app.log"
