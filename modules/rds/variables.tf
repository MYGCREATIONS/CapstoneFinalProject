variable "vpc_id" {
  description = "VPC ID for RDS and security group."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for DB subnet group (min 2 AZs)."
  type        = list(string)
}

variable "web_sg_id" {
  description = "WordPress EC2 security group ID (allow 3306 from this)."
  type        = string
}

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_user" {
  description = "Master username for RDS."
  type        = string
}

variable "db_password" {
  description = "Master password for RDS."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ for the RDS instance."
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
}

variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
}
