variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name — used for Kubernetes subnet discovery tags"
  type        = string
  default     = "eks-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (1-3, one per AZ)"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1 && length(var.public_subnet_cidrs) <= 3
    error_message = "Between 1 and 3 public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (1-3, one per AZ)"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 1 && length(var.private_subnet_cidrs) <= 3
    error_message = "Between 1 and 3 private subnet CIDRs are required."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_groups" {
  description = "EKS managed node groups configuration"
  type = map(object({
    instance_type = string
    ami_type      = string
    desired_size  = number
    min_size      = number
    max_size      = number
    capacity_type = string
    labels        = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "addon_versions" {
  description = "EKS addon versions"
  type = object({
    vpc_cni            = string
    kube_proxy         = string
    coredns            = string
    pod_identity_agent = string
  })
}
