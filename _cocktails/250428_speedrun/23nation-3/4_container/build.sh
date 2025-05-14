#!/bin/sh

cd /home/ec2-user/container/

TAG=$(TZ=Asia/Seoul date +"%Y%m%d-%H%M%S")

docker build -t foo .
docker tag foo:latest 648911607072.dkr.ecr.ap-northeast-2.amazonaws.com/foo:$TAG
docker push 648911607072.dkr.ecr.ap-northeast-2.amazonaws.com/foo:$TAG
