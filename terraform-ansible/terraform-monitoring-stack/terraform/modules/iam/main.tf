data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_monitoring" {
  name               = "${var.name_prefix}-ec2-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-monitoring-role"
  })
}

resource "aws_iam_role_policy" "prometheus_discovery" {
  name = "${var.name_prefix}-prometheus-discovery-policy"
  role = aws_iam_role.ec2_monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_monitoring_profile" {
  name = "${var.name_prefix}-ec2-monitoring-profile"
  role = aws_iam_role.ec2_monitoring.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_monitoring_profile.name
}
