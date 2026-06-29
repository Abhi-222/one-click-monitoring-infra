variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "monitoring_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "efs_file_system_id" {
  type = string
}

variable "grafana_port" {
  type = number
}

variable "node_exporter_port" {
  type = number
}

variable "prometheus_volume_size_gb" {
  description = "Size in GB for the gp3 EBS volume used by Prometheus TSDB."
  type        = number
}

variable "name" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}
