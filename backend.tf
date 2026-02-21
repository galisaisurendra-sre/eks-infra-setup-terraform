terraform {
  backend "s3" {
    bucket = "eks-infra-terraform-state-kkkkk"
    key    = "eks-infra-setup.tfstate"
    region = "us-east-1"
  }
}