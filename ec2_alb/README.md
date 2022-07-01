# EC2 ALB

Terraform code in this directory created the following infrastructure

## AWS Application load balance
This is load balance place on public subnet to server traffic from internet

## AWS LB Target Group
Define the upstream and the instance id that will process the request from ALB

## AWS EC2
3 EC2 Instance with user data that will install and configure the simple flask app as a service.

## AWS IAM Instance Profile and Role
Instance profile and iam role that will be used to allowed the ec2 instance to have the needed permission to access aws resource, in this case, access to ssm is granted for connection and troubleshooting purpose

## Security group
### LB security group
Security group for public load balancer, which allow:
- ingress from internet on port 443 and 80
- egress to wild card cidr on port 443 and 80

### EC2 security group
Security group for ec2 instance which allow:
- ingress from public load balancer on port 8080
- egress to wild card cidr on port 443 and 80
