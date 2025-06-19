export ALARM_NAME="TargetTracking-project-asg-AlarmHigh-8d70e53b-b442-43f9-8f89-4189194dee9a"
export ACTION_NAME=$(aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" --query "MetricAlarms[0].AlarmActions[0]" --output text)

aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --metric-name "CPUUtilization" \
  --namespace "AWS/EC2" \
  --statistic "Average" \
  --period 60 \
  --evaluation-periods 1 \
  --threshold 50.0 \
  --comparison-operator "GreaterThanThreshold" \
  --alarm-actions "$ACTION_NAME" \
  --dimensions "Name=AutoScalingGroupName,Value=project-asg" \
  --actions-enabled


export ALARM_NAME="TargetTracking-project-asg-AlarmLow-3241ca84-1b96-4f19-83a5-922108e1d3ab"
export ACTION_NAME=$(aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" --query "MetricAlarms[0].AlarmActions[0]" --output text)

aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --metric-name "CPUUtilization" \
  --namespace "AWS/EC2" \
  --statistic "Average" \
  --period 60 \
  --evaluation-periods 1 \
  --threshold  30 \
  --comparison-operator "LessThanThreshold" \
  --alarm-actions "$ACTION_NAME" \
  --dimensions "Name=AutoScalingGroupName,Value=project-asg" \
  --actions-enabled
