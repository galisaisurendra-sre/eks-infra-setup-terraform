locals {
  env = terraform.workspace # "dev" or "prod"

  common_tags = {
    Environment = local.env
    Project     = "eks-infra"
    ManagedBy   = "Terraform"
  }
}


