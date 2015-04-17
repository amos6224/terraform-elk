variable "name" {}
variable "region" {}
variable "instance_type" {}
variable "ami" {}
variable "subnet" {}
variable "elastic_group" {}
variable "security_groups" {}
variable "key_name" {}
variable "key_path" {}
variable "num_nodes" {}
variable "environment" {}
variable "cluster" {}

resource "aws_instance" "elastic" {

  instance_type = "${var.instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${var.ami}"
  subnet_id = "${var.subnet}"

  iam_instance_profile = "elasticSearchNode"
  associate_public_ip_address = "false"

  # Our Security group to allow HTTP and SSH access
  # other vpc
  security_groups = ["${split(",", var.security_groups)}"]

  key_name = "${var.key_name}"

  # Elasticsearch nodes
  count = "${var.num_nodes}"

  connection {
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    host = "${self.private_ip}"
    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  tags {
    Name = "elasticsearch-node-${var.name}${count.index+1}"
    es_env = "${var.environment}"
  }

  # TODO move to ansible configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Create environment template'",
      "echo 'export AWS_REGION=${var.region}' >> /tmp/elastic-environment",
      "echo 'export ES_ENVIRONMENT=${var.environment}' >> /tmp/elastic-environment",
      "echo 'export ES_CLUSTER=${var.cluster}' >> /tmp/elastic-environment",
      "echo 'export ES_GROUP=${var.elastic_group}' >> /tmp/elastic-environment"
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
