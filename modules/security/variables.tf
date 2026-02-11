variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to web instances. If empty, SSH is disabled."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "ssh_allowed_cidrs must contain valid IPv4 CIDR blocks (for example, 203.0.113.0/24)."
  }
}

variable "name_prefix" {
  description = "Name prefix for resources."
  type        = string
}

variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
}
