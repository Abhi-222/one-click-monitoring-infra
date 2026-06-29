variable "private_subnet_ids" {
  type = list(string)
}

variable "monitoring_sg_id" {
  type = string
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}
