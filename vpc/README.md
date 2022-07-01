# VPC
This terraform code create the following AWS Infrastructure

# AWS VPC
# AWS Internetgateway
To be used to connect to internet

# AWS Subnet
## Public subnet
Span accross all availability zone on current AWS region, this subnet is meant for instance or lb that can be access from internet.

## Private subnet
Span accross all availability zone on current AWS region, this subnet is meant for instance or computer engine that can access the internet but not expose to it.

# AWS Elastic IP
A persistence IP address that will be used or allocated to NAT Gateway

# AWS Nat Gateway
3 Nat Gateway place in public subnet to be used by every instance on private subnet

# AWS NACL
Firewall to allow network access from one or more subnet

# Route Table
1 Route table attached to public subnets, to route traffic from public subnet accross the availablity zone to internet gateway.
3 Route table attached to private subnets, where each route table route the traffic (to internet) from particular subnet to the respected NAT Gateway in the same availablity zone.
