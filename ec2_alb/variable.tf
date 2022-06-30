variable "service_port" {
  description = "port used for the service"
  default     = 23450
}

variable "vpc_name" {
  default = "coda-test"
}

variable "service_name" {
  default = "payment"
}
