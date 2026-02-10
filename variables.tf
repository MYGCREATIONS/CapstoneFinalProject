variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet (RDS, second AZ)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
  default     = "vockey"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "db_name" {
  description = "WordPress database name."
  type        = string
  default     = "wordpress"
}

variable "db_user" {
  description = "WordPress database user."
  type        = string
  default     = "wpuser"
}

variable "db_password" {
  description = "WordPress database password."
  type        = string
  sensitive   = true
  default     = "StrongPassword123!"
}

variable "wp_admin_user" {
  description = "WordPress admin username."
  type        = string
  default     = "admin"
}

variable "wp_admin_password" {
  description = "WordPress admin password."
  type        = string
  sensitive   = true
  default     = "AdminPassword123!"
}

variable "wp_admin_email" {
  description = "WordPress admin email."
  type        = string
  default     = "admin@example.com"
}
