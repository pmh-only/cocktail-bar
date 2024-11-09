template=$(cat $ASSETS_PATH/templates/cluster.yml)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

export REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document -H "X-aws-ec2-metadata-token: $TOKEN" | jq -r ".region")

mac=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
vpc_id=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}vpc-id)

natgw_ids=($(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$vpc_id --query "NatGateways[].NatGatewayId" --output text))
natgw_ids_s=$(IFS=, ; echo "${natgw_ids[*]}")

subnet_ids=($(aws ec2 describe-route-tables --filters "Name=route.nat-gateway-id,Values=$natgw_ids_s" --query "RouteTables[].Associations[].SubnetId" --output text))

SUBNETS=""
i=0
for subnet_id in ${subnet_ids[*]}; do
  SUBNETS+="$(printf "      subnet-$i:\n        id: $subnet_id")"
  SUBNETS+=$'\n'
  ((i++))
done

export SUBNETS
export KEY_ARN=$(aws kms create-key --query "KeyMetadata.Arn" --output text)

result=$(echo "$template" | envsubst)

echo "$result"
