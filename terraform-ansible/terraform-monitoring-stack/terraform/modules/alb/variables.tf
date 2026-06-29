variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "grafana_port" {
  type = number
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}
