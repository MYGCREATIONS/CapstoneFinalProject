variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
}

variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
}
