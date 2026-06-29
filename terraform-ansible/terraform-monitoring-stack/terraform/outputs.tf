output "bastion_public_ip" {
  description = "Public IP address for the bastion host."
  value       = module.bastion.bastion_public_ip
}

output "alb_dns_name" {
  description = "DNS name of the Grafana Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "efs_dns_name" {
  description = "EFS DNS name for the Grafana mount."
  value       = module.efs.efs_dns_name
}

output "efs_id" {
  description = "Amazon EFS File System ID."
  value       = module.efs.efs_id
}

