variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string

  default = "us-west-2"

  validation {
    condition     = length(var.aws_region) > 0
    error_message = "aws_region must be a non-empty AWS region identifier (for example, us-west-2)."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string

  default = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (for example, 10.0.0.0/16)."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string

  default = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR block (for example, 10.0.1.0/24)."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string

  default = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_subnet_cidr))
    error_message = "private_subnet_cidr must be a valid IPv4 CIDR block (for example, 10.0.2.0/24)."
  }
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet (RDS, second AZ)."
  type        = string

  default = "10.0.3.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_subnet_2_cidr))
    error_message = "private_subnet_2_cidr must be a valid IPv4 CIDR block (for example, 10.0.3.0/24)."
  }
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

  validation {
    condition     = length(var.instance_type) > 0
    error_message = "instance_type must be a non-empty EC2 instance type (for example, t3.micro)."
  }
}

variable "db_name" {
  description = "WordPress database name."
  type        = string
  default     = "wordpress"

  validation {
    condition     = length(var.db_name) > 0
    error_message = "db_name must be a non-empty database name."
  }
}

variable "db_user" {
  description = "WordPress database user."
  type        = string
  default     = "wpuser"

  validation {
    condition     = length(var.db_user) > 0
    error_message = "db_user must be a non-empty database username."
  }
}

variable "db_password" {
  description = "WordPress database password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "db_password must be at least 12 characters long."
  }
}

variable "wp_admin_user" {
  description = "WordPress admin username."
  type        = string

  validation {
    condition     = length(var.wp_admin_user) > 0
    error_message = "wp_admin_user must be a non-empty username."
  }
}

variable "wp_admin_password" {
  description = "WordPress admin password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.wp_admin_password) >= 12
    error_message = "wp_admin_password must be at least 12 characters long."
  }
}

variable "wp_admin_email" {
  description = "WordPress admin email."
  type        = string

  default = "admin@example.com"

  validation {
    condition     = can(regex("@", var.wp_admin_email))
    error_message = "wp_admin_email must be a valid email address."
  }
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access to the web EC2 instances. If empty, SSH is disabled at the security group level."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "ssh_allowed_cidrs must contain valid IPv4 CIDR blocks (for example, 203.0.113.0/24)."
  }
}
