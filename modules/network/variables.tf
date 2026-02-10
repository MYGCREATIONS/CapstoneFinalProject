variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet (for RDS subnet group, second AZ)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
}

variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
}
