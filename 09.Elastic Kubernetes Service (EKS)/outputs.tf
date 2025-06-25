output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}
