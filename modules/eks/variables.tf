variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for control plane and nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for control plane HA"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "ARN of the cluster IAM role"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the node IAM role"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
