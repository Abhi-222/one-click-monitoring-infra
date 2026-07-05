resource "aws_launch_template" "this" {
  name_prefix   = "monitoring-${var.environment}-"
  
  # Reads the dynamic ID provided directly by the AWS parameter store
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  
  name_prefix   = "${var.name_prefix}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }


  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.monitoring_sg_id]

  # Root volume
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Prometheus TSDB volume
  block_device_mappings {
    device_name = "/dev/xvdb"

    ebs {
      volume_size           = var.prometheus_volume_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }


  

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    efs_id             = var.efs_file_system_id
    grafana_port       = var.grafana_port
    node_exporter_port = var.node_exporter_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name        = var.name
      Role        = "monitoring"
      Project     = "Monitoring Infrastructure"
      Environment = var.tags["Environment"]
    })
  }

  tags = merge(var.tags, {
    Name        = var.name
    Role        = "monitoring"
    Project     = "Monitoring Infrastructure"
    Environment = var.tags["Environment"]
  })
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}
