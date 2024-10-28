#!/bin/sh

wget https://raw.githubusercontent.com/kubernetes/autoscaler/refs/heads/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml \
  -O "$(dirname $0)/cluster-autoscaler-autodiscover.yaml"
