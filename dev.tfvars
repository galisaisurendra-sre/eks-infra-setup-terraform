aws_region   = "us-east-1"
cluster_name = "eks-cluster"

# VPC CIDR provides 65,536 IPs - plenty for VPC CNI
vpc_cidr = "10.0.0.0/16"

# Use /22 subnets (1,024 IPs each) for VPC CNI to avoid IP exhaustion
# /22 = 1,024 IPs per subnet (256 usable after AWS reserves)
public_subnet_cidrs = [
  "10.0.0.0/22",      # AZ-1a: 10.0.0.0 - 10.0.3.255
  "10.0.4.0/22"       # AZ-1b: 10.0.4.0 - 10.0.7.255
]

private_subnet_cidrs = [
  "10.0.8.0/22",      # AZ-1a: 10.0.8.0 - 10.0.11.255
  "10.0.12.0/22"      # AZ-1b: 10.0.12.0 - 10.0.15.255
]

# Kubernetes Configuration
kubernetes_version = "1.32"

# EKS Addon Versions (for k8s 1.32)
addon_versions = {
  vpc_cni            = "v1.21.1-eksbuild.3"
  kube_proxy         = "v1.32.11-eksbuild.2"
  coredns            = "v1.11.4-eksbuild.28"
  pod_identity_agent = "v1.3.0-eksbuild.1"
}

# Node Pools Configuration
node_groups = {
  system = {
    instance_type = "t3.medium"
    ami_type      = "AL2023_x86_64_STANDARD"
    desired_size  = 1
    min_size      = 1
    max_size      = 3
    capacity_type = "ON_DEMAND"
    labels = {
      workload = "system"
    }
    taints = [
      {
        key    = "workload"
        value  = "system"
        effect = "NO_SCHEDULE"
      }
    ]
  }
  general = {
    instance_type = "t3.medium"
    ami_type      = "AL2023_x86_64_STANDARD"
    desired_size  = 1
    min_size      = 1
    max_size      = 3
    capacity_type = "ON_DEMAND"
    labels = {
      workload = "app"
    }
    taints = []
  }
}