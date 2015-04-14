variable "aws_access_key" {}
variable "aws_secret_key" {}

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

variable "aws_instance_type" {
  description = "EC2 instance type."
	default = "t2.medium"
}

# if you have multiple clusters sharing the same es_environment..?
variable "es_cluster" {
	description = "Elastic cluster name"
	default = "elasticsearch"
}

variable "es_environment" {
	description = "Elastic environment tag for auto discovery"
	default = "elasticsearch"
}

variable "es_num_nodes" {
	description = "Elastic nodes"
	default = "2"
}

# Ubuntu Precise 14.04 LTS (x64) built by packer
# See https://github.com/nadnerb/packer-elastic-search
variable "aws_amis" {
  default = {
		ap-southeast-2 = "ami-e95123d3"
  }
}

variable "aws_vpcs" {
	default = {
		ap-southeast-2 = "vpc-f753bd92"
	}
}

variable "aws_subnet_cidr_a" {
	default = {
		ap-southeast-2 = "172.16.55.0/25"
	}
}

variable "aws_virtual_gateway_a" {
  default = {
    ap-southeast-2 = "vgw-7241716f"
  }
}

variable "aws_virtual_gateway_cidr_a" {
  default = {
    ap-southeast-2 = "10.12.0.0/21"
  }
}

variable "aws_nat_a" {
  default = {
    ap-southeast-2 = "i-41794b7f"
  }
}

variable "aws_nat_cidr_a" {
  default = {
    ap-southeast-2 = "0.0.0.0/0"
  }
}

variable "aws_subnet_cidr_b" {
	default = {
		ap-southeast-2 = "172.16.55.155/25"
	}
}

variable "aws_virtual_gateway_b" {
  default = {
    ap-southeast-2 = "vgw-7241716f"
  }
}

variable "aws_virtual_gateway_cidr_b" {
  default = {
    ap-southeast-2 = "10.12.0.0/21"
  }
}

variable "aws_nat_b" {
  default = {
    ap-southeast-2 = "i-9fd348a1"
  }
}

variable "aws_nat_cidr_b" {
  default = {
    ap-southeast-2 = "0.0.0.0/0"
  }
}
