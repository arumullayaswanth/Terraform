####################
# IAM Roles
####################

# IAM Role for EKS Cluster
resource "aws_iam_role" "master" {
  name = "EKS-master"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach IAM Policies to Master Role
resource "aws_iam_role_policy_attachment" "eks_master_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])

  role       = aws_iam_role.master.name
  policy_arn = each.value
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "worker" {
  name = "EKS-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# AutoScaler IAM Policy
resource "aws_iam_policy" "autoscaler" {
  name = "EKS-autoscaler-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

# Attach Policies to Worker Role
resource "aws_iam_role_policy_attachment" "eks_worker_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ])

  role       = aws_iam_role.worker.name
  policy_arn = each.value
}

# Attach custom autoscaler policy
resource "aws_iam_role_policy_attachment" "autoscaler_attach" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

# Instance profile for worker nodes
resource "aws_iam_instance_profile" "worker_profile" {
  name = "EKS-worker-profile"
  role = aws_iam_role.worker.name
}

####################
# EKS Cluster
####################

resource "aws_eks_cluster" "eks" {
  name     = "project-eks"
  role_arn = aws_iam_role.master.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id
    ]
  }

  tags = {
    Name = "MyEKS"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_master_policies]
}

####################
# Node Group
####################

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "project-node-group"
  node_role_arn   = aws_iam_role.worker.arn

  subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  labels = {
    env = "dev"
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_policies,
    aws_iam_role_policy_attachment.autoscaler_attach
  ]
}