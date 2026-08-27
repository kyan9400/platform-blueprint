output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group attached to the EKS control plane."
  value       = module.eks.cluster_security_group_id
}

output "configure_kubectl" {
  description = "Command for obtaining a local kubeconfig after provisioning."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "private_subnet_ids" {
  description = "Private subnets used by managed nodes."
  value       = module.vpc.private_subnets
}

output "vpc_id" {
  description = "Platform VPC ID."
  value       = module.vpc.vpc_id
}
