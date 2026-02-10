variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance."
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the instance."
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
}

variable "user_data" {
  description = "Rendered user_data script."
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
