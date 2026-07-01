variable "aws_region" {
  description = "AWS region where infrastructure will be deployed."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform remote state."
  type        = string
  default     = "anurag-monitoring-tfstate-ap-south-1"
}

variable "backend_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "terraform-lock-table"
}

variable "project_owner" {
  description = "Project owner tag."
  type        = string
  default     = "Anurag Maurya"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidr_blocks" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_tool_cidr_blocks" {
  description = "CIDR blocks for private tool subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the bastion host."
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances."
  type        = string
  default     = "assignment-6"
}

variable "ansible_user" {
  description = "SSH user used by Ansible to access the bastion and monitoring nodes."
  type        = string
  default     = "ec2-user"
}

variable "instance_type" {
  description = "EC2 instance type for monitoring servers."
  type        = string
  default     = "t3.micro"
}

variable "grafana_port" {
  description = "Grafana HTTP port exposed by the ALB."
  type        = number
  default     = 3000
}

variable "prometheus_port" {
  description = "Prometheus HTTP port for internal access."
  type        = number
  default     = 9090
}

variable "node_exporter_port" {
  description = "Node Exporter HTTP port."
  type        = number
  default     = 9100
}

variable "prometheus_volume_size_gb" {
  description = "EBS volume size for Prometheus TSDB."
  type        = number
  default     = 50
}

variable "asg_desired_capacity" {
  description = "Desired Grafana ASG capacity."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum Grafana ASG capacity."
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "Minimum Grafana ASG capacity."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Owner       = "Anurag Maurya"
    Project     = "Monitoring Infrastructure"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
