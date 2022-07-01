variable "certificate_name" {
  description = "name for the certificate"
  default     = "coda"
}

variable "domain_name" {
  description = "domain name that is covered by the certificate"
  default     = "codatest.xyz"
}

variable "zone_name" {
  description = "route53 zone to store the acm certificate record validation"
  default     = "codatext.xyz"
}
