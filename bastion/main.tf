variable "name" {}
variable "stream" {}
variable "key_path" {}
variable "ami" {}
variable "key_name" {}
variable "security_groups" {}
variable "subnet_security_id" {}
variable "instance_type" {}

# using amazon linux instead of ubuntu
resource "aws_instance" "bastion" {
  connection {
    user = "ec2-user"
    key_file = "${var.key_path}"
  }

  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  security_groups = ["${split(",", replace(var.security_groups, "/,\s?$/", ""))}"]

  subnet_id = "${var.subnet_security_id}"
  # temporary
  associate_public_ip_address = true
  source_dest_check = false
  tags = {
    Name = "${var.name}"
    stream = "${var.stream}"
  }
}
