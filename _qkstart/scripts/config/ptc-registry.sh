TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document -H "X-aws-ec2-metadata-token: $TOKEN" | jq -r ".region")
ACCOUNT_ID=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document -H "X-aws-ec2-metadata-token: $TOKEN" | jq -r ".accountId")

read -p "Cluster name: " CLUSTER_NAME
roles="$(aws iam list-roles | jq "[.Roles[]|select(.RoleName|startswith(\"eksctl-$CLUSTER_NAME-nodegroup-p-NodeInstanceRole\"))|.RoleName]|map(. |= \"arn:aws:iam::$ACCOUNT_ID:role/\(.)\")")"

cat <<EOF > ./ptc-registry.policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": $roles
      },
      "Action": [
        "ecr:CreateRepository",
        "ecr:BatchImportUpstreamImage"
      ],
      "Resource": [
        "arn:aws:ecr:$REGION:$ACCOUNT_ID:repository/*"
      ]
    }
  ]
}
EOF

aws ecr put-registry-policy \
  --policy-text file://./ptc-registry.policy.json
