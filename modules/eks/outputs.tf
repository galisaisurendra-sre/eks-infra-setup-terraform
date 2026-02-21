output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data required for cluster connection"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_provider_url" {
  description = "OIDC Provider URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_group_ids" {
  description = "Managed node group IDs"
  value       = { for k, v in aws_eks_node_group.main : k => v.id }
}

output "node_group_arns" {
  description = "Managed node group ARNs"
  value       = { for k, v in aws_eks_node_group.main : k => v.arn }
}

output "control_plane_sg_id" {
  description = "ID of the Control Plane Security Group"
  value       = aws_security_group.control_plane.id
}

output "node_sg_id" {
  description = "ID of the Worker Node Security Group"
  value       = aws_security_group.node.id
}
