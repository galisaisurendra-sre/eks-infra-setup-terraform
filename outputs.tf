output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID for VPC interface endpoints"
  value       = module.vpc.vpc_endpoint_sg_id
}

# IAM Module Outputs
output "cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM Role"
  value       = module.iam.cluster_role_arn
}

output "node_role_arn" {
  description = "ARN of the EKS Node IAM Role"
  value       = module.iam.node_role_arn
}

# EKS Module Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

# output "oidc_provider_arn" {
#   description = "ARN of the OIDC Provider"
#   value       = module.eks.oidc_provider_arn
# }
#
# output "oidc_provider_url" {
#   description = "OIDC Provider URL for service account integration"
#   value       = module.eks.oidc_provider_url
# }

output "node_group_ids" {
  description = "Node group IDs by pool name"
  value       = module.eks.node_group_ids
}

output "control_plane_sg_id" {
  description = "ID of the Control Plane Security Group"
  value       = module.eks.control_plane_sg_id
}

output "node_sg_id" {
  description = "ID of the Worker Node Security Group"
  value       = module.eks.node_sg_id
}