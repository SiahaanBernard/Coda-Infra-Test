data "aws_region" "current" {}
data "aws_vpc" "test" {
  state = "available"
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.test.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.test.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "deployment_permision" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::simple-app-deployment-spec/*"
    ]
  }
}
