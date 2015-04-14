variable "name" {}
variable "vpc_id" {}
variable "cidr_block" {}
variable "gateway_id" {}
variable "gateway_cidr_block" {}
variable "instance_id" {}
variable "instance_cidr_block" {}

resource "aws_subnet" "elastic" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.cidr_block}"

  tags {
    Name = "elastic subnet ${var.name}"
  }
}

resource "aws_route_table" "elastic" {
  vpc_id = "${var.vpc_id}"

  route {
    gateway_id = "${var.gateway_id}"
    cidr_block = "${var.gateway_cidr_block}"
  }
  route {
    instance_id = "${var.instance_id}"
    cidr_block = "${var.instance_cidr_block}"
  }

  tags {
    Name = "elastic route table ${var.name}"
  }
}

resource "aws_route_table_association" "elastic_b" {
  subnet_id = "${aws_subnet.elastic.id}"
  route_table_id = "${aws_route_table.elastic.id}"
}
