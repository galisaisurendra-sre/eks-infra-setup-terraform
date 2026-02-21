module "vpc" {
  source = "./modules/vpc"
  env                  = local.env
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "iam" {
  source       = "./modules/iam"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  tags         = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name              = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  cluster_role_arn          = module.iam.cluster_role_arn
  node_role_arn             = module.iam.node_role_arn
  kubernetes_version        = var.kubernetes_version
  node_groups               = var.node_groups
  addon_versions            = var.addon_versions
  tags                      = local.common_tags
}