#!/bin/bash
trap 'exit 1' EXIT INT TERM

PASSWORD=$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:ap-northeast-2:993178285870:secret:project-rds-tp4j4V | jq ".SecretString" -r | jq ".password" -r)

cat <<EOF > config.json
{
  "mysql": {
    "host": "project-rdsproxy.proxy-cfgi40ymitul.ap-northeast-2.rds.amazonaws.com",
    "user": "app",
    "password": "$PASSWORD",
    "database": "dev"
  },
  "docdb": {
    "uri": "mongodb://app:app@project-docdb.cluster-cfgi40ymitul.ap-northeast-2.docdb.amazonaws.com:27018/?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false&tlsInsecure=true"
  },
  "s3": {
    "bucket": "project-frontend20250624001155574300000009"
  },
  "dynamodb": {
    "table": "project"
  }
}
EOF

/app/app
