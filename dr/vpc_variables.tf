variable "environment" {
  default = "Test"
}

variable "aws_region" {
  default = "us-east-2"
}

variable "infra_regions" {
  default = "us-east-1,us-east-2"
}

variable "route53_zone_private" {
  description = "Internal Domain name"
  default = "dr.swapstech.tv"
}

variable "route53_zone_public" {
  description = "External Domain name"
  default = "swapstech.com"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default = "10.181.0.0/16"
}

variable "peer_vpc_cidr" {
  description = "CIDR block for Peer VPC"
  default = "10.180.0.0/16"
}

variable "vpc_name" {
  default = "DR VPC"
}

variable "public_subnets" {
  type = "map"
  default = {
    az1.cidr = "10.181.0.0/24",
    az1.availability_zone = "us-east-1b",
    az2.cidr = "10.181.1.0/24",
    az2.availability_zone = "us-east-1c"
  }
}

variable "private_subnets" {
  type = "map"
  default = {
    az1.cidr = "10.181.2.0/24",
    az1.availability_zone = "us-east-1b",
    az2.cidr = "10.181.3.0/24",
    az2.availability_zone = "us-east-1c",
    az3.cidr = "10.181.4.0/24",
    az3.availability_zone = "us-east-1d"
  }
}

variable "custom_network_cidr" {
  default = "0.0.0.0/0"
}

variable "iam_instance_profile" {}
