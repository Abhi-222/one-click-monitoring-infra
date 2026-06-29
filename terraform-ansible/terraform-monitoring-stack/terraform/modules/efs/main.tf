resource "aws_efs_file_system" "this" {
  creation_token  = var.name
  encrypted       = true
  throughput_mode = "bursting"

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_efs_mount_target" "this" {
  for_each = {
    for idx, subnet_id in var.private_subnet_ids : idx => subnet_id
  }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [var.monitoring_sg_id]
}

output "efs_id" {
  value = aws_efs_file_system.this.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.this.dns_name
}
