export ALARM_NAME="TargetTracking-project-workers-AlarmHigh-9e39a79c-2acf-484d-a922-b500cf33e16a"
export ACTION_NAME=$(aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" --query "MetricAlarms[0].AlarmActions[0]" --output text)

aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --metric-name "CPUUtilization" \
  --namespace "AWS/EC2" \
  --statistic "Average" \
  --period 60 \
  --evaluation-periods 1 \
  --threshold 75.0 \
  --comparison-operator "GreaterThanThreshold" \
  --alarm-actions "$ACTION_NAME" \
  --dimensions "Name=AutoScalingGroupName,Value=project-workers" \
  --actions-enabled


export ALARM_NAME="TargetTracking-project-workers-AlarmLow-1971e15e-366d-4f5f-8996-e140f4a96102"
export ACTION_NAME=$(aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" --query "MetricAlarms[0].AlarmActions[0]" --output text)

aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --metric-name "CPUUtilization" \
  --namespace "AWS/EC2" \
  --statistic "Average" \
  --period 60 \
  --evaluation-periods 1 \
  --threshold  52.5 \
  --comparison-operator "LessThanThreshold" \
  --alarm-actions "$ACTION_NAME" \
  --dimensions "Name=AutoScalingGroupName,Value=project-workers" \
  --actions-enabled
