variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "route_type" {
  type = string
}

variable "gateway_id" {
  type    = string
  default = ""
}

variable "nat_gateway_id" {
  type    = string
  default = ""
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}
