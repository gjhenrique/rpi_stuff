terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "guigui-state"
    key    = "rpi_stuff/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}


module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "1.6.0"

  github_repositories = [
    "gjhenrique/rpi_stuff",
  ]

  iam_role_name           = "rpi-stuff-molecule"
  attach_read_only_policy = false
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "rpi-stuff-molecule-policy"
  role = module.oidc_github.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeVpcs",
          "ec2:TerminateInstances",
          "ec2:DeleteSecurityGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "molecule-network"
  cidr = "10.72.7.0/24"

  azs            = ["eu-central-1a"]
  public_subnets = ["10.72.7.0/24"]
}

output "subnet_id" {
  value = module.vpc.public_subnets[0]
}
