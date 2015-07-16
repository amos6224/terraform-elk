### MANDATORY ###
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "hosted_zone_name" {}
variable "public_hosted_zone_id" {}
variable "public_hosted_zone_name" {}

# group our resources
variable "stream_tag" {
  default = "default"
}

###################################################################
# AWS configuration below
###################################################################
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default = "elastic"
}

### MANDATORY ###
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

variable "amazon_nat_ami" {
  default = {
    eu-central-1 = "ami-46073a5b"
    ap-southeast-1 = "ami-b49dace6"
    ap-southeast-2 = "ami-e7ee9edd"
    us-west-1 = "ami-7da94839"
  }
}

###################################################################
# Vpc configuration below
###################################################################

### MANDATORY ###
variable "aws_vpc_cidr" {
  description = "VPC cidr block"
}

### MANDATORY ###
# I am currently using this until moving into VPC with a VPN connection
variable "aws_internet_gateway_id" {
  description = "existing internet gateway id"
}

###################################################################
# Vpc Peering configuration below
###################################################################

### MANDATORY ###
variable "aws_peer_owner_id" {
  description = "VPC peering owner id"
}

### MANDATORY ###
variable "aws_parent_vpc_id" {
  description = "Parent VPC id"
}

### MANDATORY ###
variable "aws_parent_vpc_cidr" {
  description = "Parent VPC id"
}

###################################################################
# Subnet configuration below
###################################################################

### MANDATORY ###
variable "aws_security_subnet_cidr_a" {
  description = "cidr for security subnet a"
}

variable "aws_security_subnet_cidr_b" {
  description = "cidr for security subnet b"
}


### MANDATORY ###
variable "aws_subnet_cidr_a" {
  description = "Subnet A cidr block"
}

### MANDATORY ###
variable "aws_subnet_public_cidr_a" {
  description = "Subnet A public cidr block"
}

### MANDATORY ###
variable "aws_subnet_cidr_b" {
  description = "Subnet B cidr block"
}

### MANDATORY ###
variable "aws_subnet_public_cidr_b" {
  description = "Subnet B public cidr block"
}
###################################################################
# Elasticsearch configuration below
###################################################################

# Ubuntu Precise 14.04 LTS (x64) built by packer
# See https://github.com/nadnerb/packer-elastic-search
variable "aws_elasticsearch_amis" {
  default = {
    ap-southeast-2 = "ami-7ff38945"
  }
}

variable "aws_elasticsearch_instance_type" {
  description = "Elasticsearch instance type."
  default = "t2.medium"
}

### MANDATORY ###
# if you have multiple clusters sharing the same es_environment..?
variable "es_cluster" {
  description = "Elastic cluster name"
}

### MANDATORY ###
variable "es_environment" {
  description = "Elastic environment tag for auto discovery"
}

# number of nodes in zone a
variable "es_num_nodes_a" {
  description = "Elastic nodes in a"
  default = "1"
}

# number of nodes in zone b
variable "es_num_nodes_b" {
  description = "Elastic nodes in b"
  default = "1"
}

# the ability to add additional existing security groups. In our case
# we have consul running as agents on the box
variable "additional_security_groups" {
  default = ""
}

###################################################################
# Logstash configuration below
###################################################################

# see https://github.com/nadnerb/packer-logstash
variable "aws_logstash_amis" {
  default = {
    ap-southeast-2 = "ami-ad4a3097"
  }
}

variable "aws_logstash_instance_type" {
  description = "Logstash instance type."
  default = "t2.small"
}

###################################################################
# Kibana configuration below
###################################################################

# https://github.com/nadnerb/packer-kibana
variable "aws_kibana_amis" {
  default = {
    ap-southeast-2 = "ami-c9522ef3"
  }
}

variable "aws_kibana_instance_type" {
  default  = "t2.small"
}

###################################################################
# Consul configuration below
###################################################################

variable "aws_consul_amis" {
  default = {
    ap-southeast-2 = "ami-8997ecb3"
  }
}

variable "allowed_cidr_blocks"{
  default = "0.0.0.0/0"
}
