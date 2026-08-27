variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "eu-central-1"
}

variable "enable_public_endpoint" {
  description = "Expose the Kubernetes API publicly. Keep false unless access CIDRs are also constrained."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.34"
}

variable "node_desired_size" {
  description = "Desired managed-node count."
  type        = number
  default     = 3
}

variable "node_instance_types" {
  description = "Allowed EC2 types for the managed node group."
  type        = list(string)
  default     = ["m7i.large"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one node instance type is required."
  }
}

variable "node_max_size" {
  description = "Maximum managed-node count."
  type        = number
  default     = 6
}

variable "node_min_size" {
  description = "Minimum managed-node count."
  type        = number
  default     = 3
}

variable "project_name" {
  description = "Prefix used for cluster resources."
  type        = string
  default     = "platform-blueprint"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "Project name must be 3-31 lowercase alphanumeric or hyphen characters."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway to reduce non-production cost. Set false for zonal production resilience."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "IPv4 CIDR allocated to the platform VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}
