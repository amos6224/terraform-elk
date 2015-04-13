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

resource "aws_subnet" "elastica" {
    vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"
    cidr_block = "${lookup(var.aws_subnet-a-cidr, var.aws_region)}"

    tags {
        Name = "elastic subnet a"
    }
}

resource "aws_route_table" "elastic" {
    vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"
    route {
        gateway_id = "vgw-7241716f"
        cidr_block = "10.12.0.0/21"
    }
    route {
        instance_id = "i-41794b7f"
        cidr_block = "0.0.0.0/0"
    }

    tags {
        Name = "elastic route table a"
    }
}

resource "aws_route_table_association" "elastic_igw" {
    subnet_id = "${aws_subnet.elastica.id}"
    route_table_id = "${aws_route_table.elastic.id}"
}

module "elastic" {
    source = "./elastic"

    region = "${var.aws_region}"
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    subnet = "${aws_subnet.elastica.id}"
    instance_type = "${var.aws_instance_type}"
    security_group = "${aws_security_group.elastic.id}"
    key_name = "${var.key_name}"
    key_path = "${var.key_path}"
    num_nodes = "${var.es_num_nodes}"
    cluster = "${var.es_cluster}"
    environment = "${var.es_environment}"
}
