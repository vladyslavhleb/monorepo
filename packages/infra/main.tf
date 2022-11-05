terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}
provider "github" {
  token = var.GITHUB_TOKEN
}

resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "${var.project_name}_${terraform.workspace}"
  }
}


resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.project_name}_${terraform.workspace}_1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.project_name}_${terraform.workspace}_2"
  }
}

resource "aws_ecr_repository" "ecr_repository_sample_1" {
  name                 = "${var.project_name}_sample1_${terraform.workspace}"
  image_tag_mutability = "MUTABLE"


  tags = {
    "Name" = "${var.project_name}_${terraform.workspace}"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ecr_repository_sample_2" {
  name                 = "${var.project_name}_sample2_${terraform.workspace}"
  image_tag_mutability = "MUTABLE"


  tags = {
    "Name" = "${var.project_name}_${terraform.workspace}"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "eks_role" {

  tags = {
    "Name" = "${var.project_name}_${terraform.workspace}"
  }

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "role_policy_1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "role_policy_2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}

data "aws_ecr_repository" "data_ecr_repository_sample_1" {
  name = aws_ecr_repository.ecr_repository_sample_1.name
}

data "aws_ecr_repository" "data_ecr_repository_sample_2" {
  name = aws_ecr_repository.ecr_repository_sample_2.name
}

resource "github_repository_environment" "gh_environment" {
  environment = terraform.workspace
  repository  = var.repository

}

resource "github_actions_environment_secret" "gh_secret_ecr_endpoint_sample1" {
  environment     = github_repository_environment.gh_environment.environment
  repository      = var.repository
  secret_name     = "ECR_IMAGE_SAMPLE_1"
  plaintext_value = data.aws_ecr_repository.data_ecr_repository_sample_1.repository_url
}



resource "github_actions_environment_secret" "gh_secret_ecr_endpoint_sample2" {
  environment     = github_repository_environment.gh_environment.environment
  repository      = var.repository
  secret_name     = "ECR_IMAGE_SAMPLE_2"
  plaintext_value = data.aws_ecr_repository.data_ecr_repository_sample_2.repository_url
}



resource "github_actions_secret" "aws_deployoment_key_id" {
  repository      = var.repository
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.AWS_ACCESS_KEY_ID
}

resource "github_actions_secret" "aws_deployoment_secret_access_key" {
  repository      = var.repository
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.AWS_SECRET_ACCESS_KEY
}

# resource "aws_eks_cluster" "terraform_eks" {

#   tags = {
#     "Name" = "terraform_eks"
#   }
#   role_arn = aws_iam_role.terraform_eks.arn

#   vpc_config {
#     subnet_ids = [aws_subnet.terraform_eks.id, aws_subnet.terraform_eks_2.id]
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
#   # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
#   depends_on = [
#     aws_iam_role_policy_attachment.terraform_eks,
#     aws_iam_role_policy_attachment.terraform_eks_2,
#   ]
# }

# output "endpoint" {
#   value = aws_eks_cluster.terraform_eks.endpoint
# }


# output "kubeconfig-certificate-authority-data" {
#   value = aws_eks_cluster.terraform_eks.certificate_authority[0].data
# }
