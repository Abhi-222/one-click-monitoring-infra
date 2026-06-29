resource "aws_cloudwatch_log_group" "asg_health" {
  name              = "/aws/autoscaling/${var.name_prefix}"
  retention_in_days = 14
  tags              = var.tags
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.asg_health.name
}
