data "aws_region" "current" {}

data "aws_availability_zones" "all" {
  state = "available"
}
