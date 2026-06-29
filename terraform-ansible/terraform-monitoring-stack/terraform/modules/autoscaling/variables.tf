variable "launch_template_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "min_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "max_size" {
  type = number
}

variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}
