provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# the instances over SSH and elastic ports
resource "aws_security_group" "elastic" {
  name = "${var.aws_security_group}"
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

resource "aws_instance" "elastic" {

  instance_type = "${var.aws_instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet_id = "${lookup(var.aws_subnets, var.aws_region)}"

  iam_instance_profile = "elasticSearchNode"
  associate_public_ip_address = "true"

  # Our Security group to allow HTTP and SSH access
  # other vpc
  security_groups = ["${aws_security_group.elastic.id}"]

  key_name = "${var.key_name}"

  # Elasticsearch nodes
  count = "${var.es_num_nodes}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    host = "${self.public_ip}"
    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  tags {
    # this may not be ideal naming our cattle like this.
    Name = "elasticsearch-node-${count.index+1}"
    es_env = "${var.es_environment}"
  }

  # TODO move to ansible configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Create environment template'",
      "echo 'export AWS_REGION=${var.aws_region}' >> /tmp/elastic-environment",
      "echo 'export ES_ENVIRONMENT=${var.es_environment}' >> /tmp/elastic-environment",
      "echo 'export ES_CLUSTER=${var.es_cluster}' >> /tmp/elastic-environment",
      "echo 'export ES_GROUP=${var.aws_security_group}' >> /tmp/elastic-environment"
    ]
  }

  provisioner "file" {
      source = "${path.module}/scripts/upstart.conf"
      destination = "/tmp/upstart.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/environment.sh",
      "${path.module}/scripts/service.sh"
    ]
  }

}
