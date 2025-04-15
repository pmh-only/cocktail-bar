#!/bin/sh

instance_ids=$(aws ec2 describe-instances --filter Name=tag:Project,Values=skills2022 | jq ".Reservations[] | .Instances[] | .InstanceId" -r)

for id in $instance_ids; do
	echo Start terminate... $id
	aws ec2 terminate-instances --instance-id $id
done
