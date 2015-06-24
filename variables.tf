### MANDATORY ###
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "hosted_zone_name" {}

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

# ELASTIC SEARCH INSTANCE TYPE TODO RENAME
variable "aws_instance_type" {
  description = "EC2 instance type."
  default = "t2.medium"
}

variable "amazon_nat_ami" {
  default = {
    ap-southeast-2 = "ami-e7ee9edd"
  }
}

###################################################################
# Vpc configuration below
###################################################################

variable "aws_vpc_cidr" {
  description = "VPC cidr block"
}

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

### MANDATORY ###
variable "aws_peer_cidr" {
  description = "Peered destination cidr"
}

###################################################################
# Subnet configuration below
###################################################################

### MANDATORY ###
variable "aws_security_subnet_cidr" {
  description = "cidr for security subnet"
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

# Ubuntu Precise 14.04 LTS (x64) built by packer
# See https://github.com/nadnerb/packer-elastic-search
variable "aws_amis" {
  default = {
    ap-southeast-2 = "ami-e95123d3"
  }
}

###################################################################
# Logstash configuration below
###################################################################

variable "aws_logstash_amis" {
  default = {
    ap-southeast-2 = "ami-ad4a3097"
  }
}

###################################################################
# Kibana configuration below
###################################################################

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
