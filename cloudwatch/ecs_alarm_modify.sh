export ALARM_NAME="TargetTracking-project-node-20250321020536143700000029-AlarmLow-17efe978-9cae-4bd3-b232-2022fa6ae8a5"
export ACTION_NAME=$(aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" --query "MetricAlarms[0].AlarmActions[0]" --output text)
export CLUSTER_NAME=$(aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" --query 'MetricAlarms[0].Dimensions[?Name==`ClusterName`].Value' --output text)

aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --metric-name "CapacityProviderReservation" \
  --namespace "AWS/ECS/ManagedScaling" \
  --statistic "Average" \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 100 \
  --comparison-operator "LessThanThreshold" \
  --alarm-actions "$ACTION_NAME" \
  --dimensions "Name=CapacityProviderName,Value=EC2" "Name=ClusterName,Value=$CLUSTER_NAME" \
  --actions-enabled
