provider "aws" {
  region = "us-west-2" # Adjust your region accordingly
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
}
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.21"
  subnets         = [aws_subnet.public.id, aws_subnet.private.id]
  vpc_id          = aws_vpc.eks_vpc.id

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }

  tags = {
    Environment = "dev"
  }
}
resource "aws_iam_role" "eks_role" {
  name = "eks-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "eks.amazonaws.com"
    },
    "Effect": "Allow"
  }
}
EOF
}
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-microservice-repo"
}

