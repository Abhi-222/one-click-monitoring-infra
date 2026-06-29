variable "vpc_id" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "grafana_port" {
  type = number
}

variable "prometheus_port" {
  type = number
}

variable "node_exporter_port" {
  type = number
}

variable "name_bastion" {
  type = string
}

variable "name_alb" {
  type = string
}

variable "name_monitoring" {
  type = string
}

variable "tags" {
  type = map(string)
}
