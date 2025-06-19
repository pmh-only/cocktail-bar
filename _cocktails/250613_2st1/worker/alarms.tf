resource "aws_cloudwatch_metric_alarm" "ec2_high" {
  alarm_name          = "ec2_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 70

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 60
  statistic   = "Average"
  dimensions = {
    AutoScalingGroupName = "project-asg"
  }
}


resource "aws_cloudwatch_metric_alarm" "ec2_low" {
  alarm_name          = "ec2_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 50

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 60
  statistic   = "Average"
  dimensions = {
    AutoScalingGroupName = "project-asg"
  }
}
