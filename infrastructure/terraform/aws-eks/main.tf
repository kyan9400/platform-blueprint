data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "${var.project_name}-${var.environment}"
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Repository  = "github.com/kyan9400/platform-blueprint"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs
  private_subnets = [
    for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, index)
  ]
  public_subnets = [
    for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, index + 48)
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.0"

  name               = local.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_private_access = true
  endpoint_public_access  = var.enable_public_endpoint

  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    platform = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      labels = {
        role = "platform-workload"
      }

      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }

  tags = local.tags
}

check "node_group_size_order" {
  assert {
    condition = (
      var.node_min_size <= var.node_desired_size &&
      var.node_desired_size <= var.node_max_size
    )
    error_message = "Node sizes must satisfy min_size <= desired_size <= max_size."
  }
}
