provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

/*resource "aws_vpc" "supersearch" {
    cidr_block = "172.33.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support  = true

    tags {
        Name = "supersearch vpc"
    }
}

resource "aws_internet_gateway" "supersearch" {
    vpc_id = "${aws_vpc.supersearch.id}"

    tags {
        Name = "supersearch gateway"
    }
}

resource "aws_route_table" "supersearch" {
    vpc_id = "${aws_vpc.supersearch.id}"
    route {
        cidr_block = "172.33.0.0/16"
        gateway_id = "${aws_internet_gateway.supersearch.id}"
    }

    tags {
        Name = "supersearch route table"
    }
}

# create 2 for multi az
resource "aws_subnet" "supersearch" {
    vpc_id = "${aws_vpc.supersearch.id}"
    cidr_block = "172.33.1.0/24"
    availability_zone = "ap-southeast-2b"
    tags {
        Name = "supersearch subnet b"
    }
}

resource "aws_route_table_association" "supersearch" {
    subnet_id = "${aws_subnet.supersearch.id}"
    route_table_id = "${aws_route_table.supersearch.id}"
}*/

# the instances over SSH and elastic ports
resource "aws_security_group" "elastic" {
    name = "elasticsearch"
    description = "Supersearch ES ports with ssh"

    # SSH access from anywhere
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # vpc_id = "${aws_vpc.supersearch.id}"
    vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

    # lock down
    ingress {
        from_port = 9200
        to_port = 9399
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
      Name = "supersearch"
    }

}


#resource "aws_elb" "elastic" {
#  name = "elastic-elb"
#
  # The same availability zone as our instance
  #availability_zones = ["${aws_instance.elastic.availability_zone}"]
  #subnet_id = "${lookup(var.aws_subnet, var.aws_region)}"

#  listener {
#    instance_port = 9200
#    instance_protocol = "http"
#    lb_port = 9200
#    lb_protocol = "http"
#  }

  # The instance is registered automatically
#  instances = ["${aws_instance.elastic.id}"]
#}

resource "aws_instance" "elastic" {

  instance_type = "${var.aws_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  # subnet_id = "${aws_subnet.supersearch.id}"
  subnet_id = "subnet-09c53a6c"

  iam_instance_profile = "elasticSearchNode"
  associate_public_ip_address = "false"

  key_name = "${var.key_name}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    host = "${self.private_ip}"
    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  # Our Security group to allow HTTP and SSH access
  # other vpc
  security_groups = ["${aws_security_group.elastic.id}"]

  tags {
    Name = "supersearch-node-${count.index+1}"
    es_env = "${var.es_environment}"
  }

  # Start elasticsearch
  provisioner "remote-exec" {
    inline = [ "sudo ES_ENVIRONMENT=${var.es_environment} ES_CLUSTER=${var.es_cluster} ES_GROUP=${var.aws_security_group} AWS_REGION=${var.aws_region} /etc/init.d/elasticsearch start" ]
  }

  # This will create 2 instances
  count = 2
}
