provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
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

    ingress {
        from_port = 9200
        to_port = 9399
        protocol = "tcp"
        #cidr_blocks = ["115.186.199.54/32"]
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
      Name = "orca-elasticsearch-private-vpc"
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

  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  instance_type = "t2.medium"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet_id = "${lookup(var.aws_subnet, var.aws_region)}"
  iam_instance_profile = "elasticSearchNode"
  associate_public_ip_address = "false"

  key_name = "${var.key_name}"

  # Our Security group to allow HTTP and SSH access
  # other vpc
  security_groups = ["${aws_security_group.elastic.id}"]

  tags {
    Name = "talentsearch-es-private-vpc"
    es_env = "${var.es_environment}"
  }

  # Start elasticsearch (this require public ip)
  #provisioner "remote-exec" {
  #  inline = [
  #       "sudo ES_CLUSTER=${var.es_cluster} ES_ENVIRONMENT=${var.es_environment} ES_GROUP=${var.aws_security_group} AWS_REGION=${var.aws_region} /usr/share/elasticsearch/bin/elasticsearch -Des.config=/etc/elasticsearch/elasticsearch.yml &"
  #  ]
  #}

  # This will create 2 instances
  count = 2
}
