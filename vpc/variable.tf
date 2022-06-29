variable "vpc_cidr_ip" {
  description = "CIDR ip address for VPC"
}

variable "vpc_name" {
  description = "Name for the VPC"
}

variable "is_dns_hostnames_enabled" {
  description = "define whether or not to enable dns hostnames in vpc"
  default     = true
}

variable "is_dns_support_enabled" {
  description = "define whether or not to enable dns support in vpc"
  default     = true
}
