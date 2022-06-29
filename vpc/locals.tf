locals {
  public_subnets = {
    sub-1 = {
      az   = data.aws_availability_zones.all.names[0]
      cidr = cidrsubnet(var.vpc_cidr_ip, 4, 0)
    }
    sub-2 = {
      az   = data.aws_availability_zones.all.names[1]
      cidr = cidrsubnet(var.vpc_cidr_ip, 4, 1)
    }
    sub-3 = {
      az   = data.aws_availability_zones.all.names[2]
      cidr = cidrsubnet(var.vpc_cidr_ip, 4, 2)
    }
  }
  private_subnets = {
    sub-1 = {
      az   = data.aws_availability_zones.all.names[0]
      cidr = cidrsubnet(var.vpc_cidr_ip, 4, 3)
    }
    sub-2 = {
      az   = data.aws_availability_zones.all.names[1]
      cidr = cidrsubnet(var.vpc_cidr_ip, 4, 4)
    }
    sub-3 = {
      az   = data.aws_availability_zones.all.names[2]
      cidr = cidrsubnet(var.vpc_cidr_ip, 4, 5)
    }
  }
}
