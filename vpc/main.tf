resource "aws_vpc" "prod" {
  cidr_block           = var.vpc_cidr_ip
  instance_tenancy     = "default"
  enable_dns_hostnames = var.is_dns_hostnames_enabled
  enable_dns_support   = var.is_dns_support_enabled
  tags = {
    Name = var.vpc_name
  }
}


resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "coda-test internet gateway"
  }
}

resource "aws_default_vpc_dhcp_options" "default_dhcp" {
  depends_on = [aws_vpc.prod]
  tags = {
    Name = format("%s-default-dopt", var.vpc_name)
  }
}

resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.all.names)
  vpc_id                  = aws_vpc.prod.id
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.all.names, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr_ip, 4, count.index)
  tags = merge(
    {
      "Name" = format(
        "%s-public-%s",
        var.vpc_name,
        substr(element(data.aws_availability_zones.all.names, count.index), -1, 1),
      )
    },
    {
      "Tier" = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.all.names)
  vpc_id            = aws_vpc.prod.id
  availability_zone = element(data.aws_availability_zones.all.names, count.index)
  cidr_block        = cidrsubnet(var.vpc_cidr_ip, 4, count.index + length(data.aws_availability_zones.all.names))
  tags = merge(
    {
      "Name" = format(
        "%s-private-%s",
        var.vpc_name,
        substr(element(data.aws_availability_zones.all.names, count.index), -1, 1),
      )
    },
    {
      "Tier" = "private"
    }
  )
}

resource "aws_eip" "nat" {
  count = length(data.aws_availability_zones.all.names)
  vpc   = true
  tags = {
    Description = format("EIP for NAT gateway in %s", element(data.aws_availability_zones.all.names, count.index))
  }
}

resource "aws_nat_gateway" "private" {
  count         = length(aws_eip.nat)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on = [
    aws_internet_gateway.prod
  ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.prod.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.private.*.id, count.index)
  }
  tags = {
    Name = format("route table for private subnet %s", element(aws_subnet.private.*.id, count.index))
  }
  lifecycle {
    ignore_changes = [id]
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}
resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.prod.default_network_acl_id

  ingress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    to_port    = "0"
  }

  egress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    to_port    = "0"
  }
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}
/*
resource "aws_route_table" "public" {

}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.prod.id
  for_each                = local.public_subnets
  map_public_ip_on_launch = true
  availability_zone       = each.value["az"]
  cidr_block              = each.value["cidr"]
  tags = merge({
    Name = format("%s-public-%s", var.vpc_name, each.value["az"])
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.prod.id
  for_each          = local.private_subnets
  availability_zone = each.value["az"]
  cidr_block        = each.value["cidr"]
  tags = merge({
    Name = format("%s-private-%s", var.vpc_name, each.value["az"])
  })
}
resource "aws_eip" "nat" {
  for_each = local.public_subnets
  vpc      = true
}

resource "aws_nat_gateway" "prod" {
  for_each      = aws_eip.nat
  allocation_id = each.value.id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.prod]

  lifecycle {
    ignore_changes = [id]
  } 
}

resource "aws_default_vpc_dhcp_options" "default_dhcp" {
  depends_on = [aws_vpc.prod]
  tags = {
    Name = format("%s-default-dopt", var.vpc_name)
  }
}

*/
