output "cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM Role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS Cluster IAM Role"
  value       = aws_iam_role.cluster.name
}

output "node_role_arn" {
  description = "ARN of the EKS Node IAM Role"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the EKS Node IAM Role"
  value       = aws_iam_role.node.name
}

output "node_instance_profile_arn" {
  description = "ARN of the Node Instance Profile"
  value       = aws_iam_instance_profile.node.arn
}
