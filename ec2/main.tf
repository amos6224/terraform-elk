variable "name" {}
variable "region" {}
variable "instance_type" {}
variable "ami" {}
variable "subnet" {}
variable "security_groups" {}
variable "key_name" {}
variable "key_path" {}
variable "num_nodes" {}
variable "stream_tag" {}

# needs to be renamed
resource "aws_instance" "ec2" {

  instance_type = "${var.instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${var.ami}"
  subnet_id = "${var.subnet}"

  associate_public_ip_address = "false"

  # Our Security groups
  security_groups = ["${split(",", replace(var.security_groups, "/,\s?$/", ""))}"]

  key_name = "${var.key_name}"

  # Logstash nodes
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
    Name = "${var.name}_node-${count.index+1}"
    Stream = "${var.stream_tag}"
    consul = "agent"
  }

}
