#!/bin/sh

instance_ids=$(aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | select(.InstanceId!="i-03729059d627e2037") | .InstanceId' -r)

for id in $instance_ids; do
	echo Start terminate... $id
	aws ec2 terminate-instances --instance-id $id
done
