
##############################################################################
# Bastion Server
##############################################################################

resource "aws_security_group" "bastion" {
  name = "bastion"
  description = "Allow access from allowed_network to SSH/Consul/Web, and NAT internal traffic"
  vpc_id = "${var.aws_parent_vpc_id}"

  # SSH
  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    /*cidr_blocks = [ "${var.allowed_network}" ]*/
    self = false
  }

  # Consul
  ingress = {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    /*cidr_blocks = [ "${var.allowed_network}" ]*/
    self = false
  }

  # Web
  ingress = {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    /*cidr_blocks = [ "${var.allowed_network}" ]*/
    self = false
  }

  # NAT
  /*ingress {*/
    /*from_port = 0*/
    /*to_port = 65535*/
    /*protocol = "tcp"*/
    /*cidr_blocks = [*/
      /*"${aws_subnet.public.cidr_block}",*/
      /*"${aws_subnet.private.cidr_block}"*/
    /*]*/
    /*self = false*/
  /*}*/
}

/*TOOD use this when everything else works*/
resource "aws_security_group" "allow_bastion" {
  name = "allow_bastion_ssh"
  description = "Allow access from bastion host"
  vpc_id = "${var.aws_parent_vpc_id}"
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
    self = false
  }
}

# we already have a gateway, otherwise uncomment this and use it in your routes below
/*resource "aws_internet_gateway" "security" {
    vpc_id = "${var.aws_parent_vpc_id}"

    tags {
      Name = "security internet gateway"
      Stream = "security"
    }
}*/

resource "aws_route_table" "security" {
  vpc_id = "${var.aws_parent_vpc_id}"

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.search_to_parent.id}"
    cidr_block = "${var.aws_subnet_cidr_a}"
  }

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.search_to_parent.id}"
    cidr_block = "${var.aws_subnet_cidr_b}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.aws_internet_gateway_id}"
    # gateway_id = "${aws_internet_gateway.security.id}"
  }

  tags {
    Name = "security route table"
    Stream = "security"
  }
}

resource "aws_subnet" "security" {
  vpc_id = "${var.aws_parent_vpc_id}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${var.aws_security_subnet_cidr}"

  tags {
    Name = "security subnet"
    Stream = "security"
  }
}

resource "aws_route_table_association" "security" {
  subnet_id = "${aws_subnet.security.id}"
  route_table_id = "${aws_route_table.security.id}"
}

# using amazon linux instead of ubuntu
resource "aws_instance" "bastion" {

  connection {
    user = "ec2-user"
    key_file = "${var.key_path}"
  }

  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  security_groups = [
    "${aws_security_group.bastion.id}"
  ]

  subnet_id = "${aws_subnet.security.id}"
  # temporary
  associate_public_ip_address = true
  source_dest_check = false
  tags = {
    Name = "bastion server"
    Stream = "security"
  }
}

output "bastion ip" {
  value = "${aws_instance.bastion.public_ip}"
}
