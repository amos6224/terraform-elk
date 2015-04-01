variable "access_key" {}
variable "secret_key" {}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
	default = "elastic"
}

variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "ap-southeast-2"
}

variable "aws_security_group" {
  description = "Name of security group to use in AWS."
	default = "elasticsearch"
}

variable "es_cluster" {
	description = "Elastic cluster name"
	default = "talentsearch"
}

variable "es_environment" {
	description = "Elastic environment tag for auto discovery"
	default = "talentsearch"
}

# Ubuntu Precise 14.04 LTS (x64)
variable "aws_amis" {
  default = {
		ap-southeast-2 = "ami-2ffb8815"
  }
}

variable "aws_vpcs" {
	default = {
		ap-southeast-2 = "vpc-f753bd92"
	}
}

variable "aws_subnet" {
	default = {
		ap-southeast-2 = "subnet-5fc53a3a"
	}
}
