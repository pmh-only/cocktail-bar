#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Specify the region (change this as needed)
REGION="us-east-1"
# Get the current date/time for naming snapshots/backups
DATE=$(date +%Y%m%d%H%M%S)

echo "Starting snapshot/backup creation in region: $REGION"

#############################
# RDS Clusters
#############################
echo "Processing RDS clusters..."
# List all RDS clusters (Aurora clusters)
rds_clusters=$(aws rds describe-db-clusters --region "$REGION" --query "DBClusters[].DBClusterIdentifier" --output text)

for cluster in $rds_clusters; do
  snapshot_id="${cluster}-snapshot-${DATE}"
  echo "Creating snapshot for RDS cluster: $cluster as $snapshot_id"
  aws rds create-db-cluster-snapshot \
      --db-cluster-identifier "$cluster" \
      --db-cluster-snapshot-identifier "$snapshot_id" \
      --region "$REGION"
done

#############################
# Redshift Clusters
#############################
echo "Processing Redshift clusters..."
# List all Redshift clusters
redshift_clusters=$(aws redshift describe-clusters --region "$REGION" --query "Clusters[].ClusterIdentifier" --output text)

for cluster in $redshift_clusters; do
  snapshot_id="${cluster}-snapshot-${DATE}"
  echo "Creating snapshot for Redshift cluster: $cluster as $snapshot_id"
  aws redshift create-cluster-snapshot \
      --cluster-identifier "$cluster" \
      --snapshot-identifier "$snapshot_id" \
      --region "$REGION"
done

#############################
# ElastiCache Replication Groups
#############################
echo "Processing ElastiCache replication groups..."
# List all replication groups (typically used for Redis clusters)
elasticache_rgs=$(aws elasticache describe-replication-groups --region "$REGION" --query "ReplicationGroups[].ReplicationGroupId" --output text)

for rg in $elasticache_rgs; do
  snapshot_name="${rg}-snapshot-${DATE}"
  echo "Creating snapshot for ElastiCache replication group: $rg as $snapshot_name"
  aws elasticache create-snapshot \
      --replication-group-id "$rg" \
      --snapshot-name "$snapshot_name" \
      --region "$REGION"
done

#############################
# DynamoDB Tables (Backups)
#############################
echo "Processing DynamoDB tables..."
# List all DynamoDB tables
dynamodb_tables=$(aws dynamodb list-tables --region "$REGION" --query "TableNames[]" --output text)

for table in $dynamodb_tables; do
  backup_name="${table}-backup-${DATE}"
  echo "Creating backup for DynamoDB table: $table as $backup_name"
  aws dynamodb create-backup \
      --table-name "$table" \
      --backup-name "$backup_name" \
      --region "$REGION"
done

echo "All snapshots/backups creation processes have been initiated."
