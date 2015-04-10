provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

# the instances over SSH and elastic ports
resource "aws_security_group" "elastic" {
    name = "elasticsearch"
    description = "Elasticsearch ports with ssh"

    # SSH access from anywhere
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

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

resource "aws_instance" "elastic" {

  instance_type = "${var.aws_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet_id = "${lookup(var.aws_subnets, var.aws_region)}"

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
    # this may not be ideal naming our cattle like this.
    Name = "elasticsearch-node-${count.index+1}"
    es_env = "${var.es_environment}"
  }

  # Start elasticsearch
  provisioner "remote-exec" {
    inline = [ "sudo ES_ENVIRONMENT=${var.es_environment} ES_CLUSTER=${var.es_cluster} ES_GROUP=${var.aws_security_group} AWS_REGION=${var.aws_region} /etc/init.d/elasticsearch start" ]
  }

  count = "${var.es_num_nodes}"
}
