provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# the instances over SSH and elastic ports
resource "aws_security_group" "elastic" {
  name = "elasticsearch"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # elastic ports from anywhere.. we are using private ips so shouldn't
  # have people deleting our indexes just yet
  ingress {
    from_port = 9200
    to_port = 9399
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "elasticsearch security group"
  }
}

module "subnet_a" {
  source = "./subnet"

  name = "a"
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"
  cidr_block = "${lookup(var.aws_subnet_cidr_a, var.aws_region)}"
  gateway_id = "${lookup(var.aws_virtual_gateway_a, var.aws_region)}"
  gateway_cidr_block = "${lookup(var.aws_virtual_gateway_cidr_b, var.aws_region)}"
  instance_id = "${lookup(var.aws_nat_a, var.aws_region)}"
  instance_cidr_block = "${lookup(var.aws_nat_cidr_a, var.aws_region)}"
}

module "elastic_nodes_a" {
    source = "./elastic"

    name = "a"
    region = "${var.aws_region}"
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    subnet = "${module.subnet_a.id}"
    instance_type = "${var.aws_instance_type}"
    security_group = "${aws_security_group.elastic.id}"
    key_name = "${var.key_name}"
    key_path = "${var.key_path}"
    num_nodes = "${var.es_num_nodes}"
    cluster = "${var.es_cluster}"
    environment = "${var.es_environment}"
}

module "subnet_b" {
  source = "./subnet"

  name = "b"
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"
  cidr_block = "${lookup(var.aws_subnet_cidr_b, var.aws_region)}"
  gateway_id = "${lookup(var.aws_virtual_gateway_b, var.aws_region)}"
  gateway_cidr_block = "${lookup(var.aws_virtual_gateway_cidr_b, var.aws_region)}"
  instance_id = "${lookup(var.aws_nat_b, var.aws_region)}"
  instance_cidr_block = "${lookup(var.aws_nat_cidr_b, var.aws_region)}"
}

module "elastic_nodes_b" {
    source = "./elastic"

    name = "b"
    region = "${var.aws_region}"
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    subnet = "${module.subnet_b.id}"
    instance_type = "${var.aws_instance_type}"
    security_group = "${aws_security_group.elastic.id}"
    key_name = "${var.key_name}"
    key_path = "${var.key_path}"
    num_nodes = "${var.es_num_nodes}"
    cluster = "${var.es_cluster}"
    environment = "${var.es_environment}"
}
