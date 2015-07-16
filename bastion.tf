
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

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*TOOD use this when everything else works*/
/*resource "aws_security_group" "allow_bastion" {*/
  /*name = "allow_bastion_ssh"*/
  /*description = "Allow access from bastion host"*/
  /*vpc_id = "${var.aws_parent_vpc_id}"*/

  /*ingress {*/
    /*from_port = 0*/
    /*to_port = 65535*/
    /*protocol = "tcp"*/
    /*security_groups = ["${aws_security_group.bastion.id}"]*/
    /*self = false*/
  /*}*/
/*}*/

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
    cidr_block = "${var.aws_vpc_cidr}"
  }

# we want to change this to remove this to only be accessible from our network
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.aws_internet_gateway_id}"
    # gateway_id = "${aws_internet_gateway.security.id}"
  }

  tags {
    Name = "security route table"
    stream = "security"
  }
}

resource "aws_subnet" "security_a" {
  vpc_id = "${var.aws_parent_vpc_id}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${var.aws_security_subnet_cidr_a}"

  tags {
    Name = "security subnet a"
    stream = "security"
  }
}

resource "aws_subnet" "security_b" {
  vpc_id = "${var.aws_parent_vpc_id}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${var.aws_security_subnet_cidr_b}"

  tags {
    Name = "security subnet b"
    stream = "security"
  }
}

resource "aws_route_table_association" "security_a" {
  subnet_id = "${aws_subnet.security_a.id}"
  route_table_id = "${aws_route_table.security.id}"
}

resource "aws_route_table_association" "security_b" {
  subnet_id = "${aws_subnet.security_b.id}"
  route_table_id = "${aws_route_table.security.id}"
}

module "bastion_servers_a" {
  source = "./bastion"

  name = "bastion_server_a"
  stream = "security"
  key_path = "${var.key_path}"
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  key_name = "${var.key_name}"
  security_groups = "${aws_security_group.bastion.id}"
  subnet_security_id = "${aws_subnet.security_a.id}"
  instance_type = "t2.micro"
}

module "bastion_servers_b" {
  source = "./bastion"

  name = "bastion_server_b"
  stream = "security"
  key_path = "${var.key_path}"
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"
  key_name = "${var.key_name}"
  security_groups = "${aws_security_group.bastion.id}"
  subnet_security_id = "${aws_subnet.security_b.id}"
  instance_type = "t2.micro"
}
