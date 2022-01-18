resource "aws_eip" "nat" {
  count = 3

  vpc = true
}

variable "region" {
    default = "ap-south"
    description = "AWS Region"
}

provider "aws" {
    region = var.region
}

data "aws_availibility_zones" "available" {}

locals {
    cluster_name = "eks-{$random_string.suffix.result}"
}

resource "random_string" "suffix" {
    length = 8
    special = false
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name = "dragon-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availibility_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway  = true
  enable_dns_hostnames = true

  
#  reuse_nat_ips       = true                    
#  external_nat_ip_ids = "${aws_eip.nat.*.id}" 

  tags = {
    Terraform = "true"
    Environment = "dev"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}