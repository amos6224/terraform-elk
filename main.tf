provider "aws" {
  region = "${var.aws_region}"
}

##############################################################################
# VPC and subnet configuration
##############################################################################
resource "aws_vpc" "search" {
  cidr_block = "${var.aws_vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "search"
    stream = "${var.stream_tag}"
  }
}

resource "aws_internet_gateway" "search" {
  vpc_id = "${aws_vpc.search.id}"

  tags {
    Name = "search internet gateway"
    stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "search" {
  domain_name = "${var.aws_region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Name = "search internal"
    stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_search" {
  vpc_id = "${aws_vpc.search.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.search.id}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_zone" "search" {
  name = "${var.hosted_zone_name}"
  vpc_id = "${aws_vpc.search.id}"

  tags {
    Name = "search internal"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# VPC Peering
##############################################################################

resource "aws_vpc_peering_connection" "search_to_parent" {
  peer_owner_id = "${var.aws_peer_owner_id}"
  peer_vpc_id = "${var.aws_parent_vpc_id}"
  vpc_id = "${aws_vpc.search.id}"
  auto_accept = true

  tags {
    Name = "search to parent peering"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Public Subnets
##############################################################################

resource "aws_route_table" "search_public" {
  vpc_id = "${aws_vpc.search.id}"

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.search_to_parent.id}"
    cidr_block = "${var.aws_parent_vpc_cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.search.id}"
  }

  tags {
    Name = "search public route table"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_public_a" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${var.aws_subnet_public_cidr_a}"

  tags {
    Name = "SearchPublicA"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_public_b" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${var.aws_subnet_public_cidr_b}"

  tags {
    Name = "SearchPublicB"
    stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "search_public_a" {
  subnet_id = "${aws_subnet.search_public_a.id}"
  route_table_id = "${aws_route_table.search_public.id}"
}

resource "aws_route_table_association" "search_public_b" {
  subnet_id = "${aws_subnet.search_public_b.id}"
  route_table_id = "${aws_route_table.search_public.id}"
}

##############################################################################
# NAT Boxes
##############################################################################

resource "aws_security_group" "nat" {
  name = "nat search"
  description = "NAT search security group"
  vpc_id = "${aws_vpc.search.id}"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.aws_nat_subnet_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "nat search security group"
    stream = "${var.stream_tag}"
  }
}

# Nat box
resource "aws_instance" "nat_a" {

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id = "${aws_subnet.search_public_a.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.nat.id}"]
  key_name = "${var.key_name}"
  count = "1"

  source_dest_check = false

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    host = "${self.private_ip}"
    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  tags {
    Name = "NAT_search-a"
    stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "nat_b" {

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id = "${aws_subnet.search_public_b.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.nat.id}"]
  key_name = "${var.key_name}"
  count = "1"

  source_dest_check = false

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    host = "${self.private_ip}"
    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  tags {
    Name = "NAT_search-b"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Private subnets
##############################################################################

resource "aws_route_table" "search_a" {
  vpc_id = "${aws_vpc.search.id}"

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.search_to_parent.id}"
    cidr_block = "${var.aws_parent_vpc_cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat_a.id}"
  }

  tags {
    Name = "search private route table a"
    stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "search_b" {
  vpc_id = "${aws_vpc.search.id}"

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.search_to_parent.id}"
    cidr_block = "${var.aws_parent_vpc_cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat_b.id}"
  }

  tags {
    Name = "search private route table b"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_a" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${var.aws_subnet_cidr_a}"

  tags {
    Name = "SearchPrivateA"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_b" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${var.aws_subnet_cidr_b}"

  tags {
    Name = "SearchPrivateB"
    stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "search_a" {
  subnet_id = "${aws_subnet.search_a.id}"
  route_table_id = "${aws_route_table.search_a.id}"
}

resource "aws_route_table_association" "search_b" {
  subnet_id = "${aws_subnet.search_b.id}"
  route_table_id = "${aws_route_table.search_b.id}"
}

##############################################################################
# Consul servers
##############################################################################
resource "aws_security_group" "consul_server" {
  name = "consul server"
  description = "Consul server, UI and maintenance."
  vpc_id = "${aws_vpc.search.id}"

  // These are for maintenance
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // consul ui
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul server security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_security_group" "consul_agent" {
  name = "consul agent"
  description = "Consul agents internal traffic."
  vpc_id = "${aws_vpc.search.id}"

  // These are for internal traffic
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    self = true
  }

  tags {
    Name = "consul agent security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_security_group" "consul_elb" {
  name = "consul elb"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${aws_vpc.search.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.allowed_cidr_blocks}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul elb security group"
    stream = "${var.stream_tag}"
  }
}

module "consul_servers_a" {
  source = "./consul_server"

  name = "a"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_consul_amis, var.aws_region)}"
  # public for the moment
  subnet = "${aws_subnet.search_public_a.id}"
  # fixme
  instance_type = "t2.micro"
  security_groups = "${concat(aws_security_group.consul_server.id, ",", aws_security_group.consul_agent.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  # fixme (both az with odd number)
  num_nodes = "1"
  stream_tag = "${var.stream_tag}"
}

module "consul_servers_b" {
  source = "./consul_server"

  name = "b"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_consul_amis, var.aws_region)}"
  # public for the moment
  subnet = "${aws_subnet.search_public_b.id}"
  #fixme
  instance_type = "t2.micro"
  security_groups = "${concat(aws_security_group.consul_server.id, ",", aws_security_group.consul_agent.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  # fixme (both az with odd number)
  num_nodes = "1"
  stream_tag = "${var.stream_tag}"
}

resource "aws_elb" "consul" {
  name = "consul-elb"
  security_groups = ["${aws_security_group.consul_elb.id}"]
  subnets = ["${aws_subnet.search_public_a.id}","${aws_subnet.search_public_b.id}" ]

  listener {
    instance_port = 8500
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:8500"
    interval = 30
  }

  instances = ["${module.consul_servers_a.ids}", "${module.consul_servers_b.ids}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  internal = false

  tags {
    Name = "consul elb"
    stream = "${var.stream_tag}"
  }
}

resource "aws_route53_record" "consul" {
  zone_id = "${var.public_hosted_zone_id}"
  name = "consul.${var.public_hosted_zone_name}"
  type = "A"

  alias {
    name = "${aws_elb.consul.dns_name}"
    zone_id = "${aws_elb.consul.zone_id}"
    evaluate_target_health = true
  }
}

##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elastic" {
  name = "elasticsearch"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${aws_vpc.search.id}"

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
    to_port = 9400
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "elasticsearch security group"
    stream = "${var.stream_tag}"
    cluster = "${var.es_cluster}"
  }
}

# elastic instances subnet a
module "elastic_nodes_a" {
  source = "./elastic"

  name = "a"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_elasticsearch_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.aws_elasticsearch_instance_type}"
  security_groups = "${concat(aws_security_group.consul_agent.id, ",", aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_a}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

# elastic instances subnet b
module "elastic_nodes_b" {
  source = "./elastic"

  name = "b"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_elasticsearch_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_b.id}"
  instance_type = "${var.aws_elasticsearch_instance_type}"
  security_groups = "${concat(aws_security_group.consul_agent.id, ",", aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_b}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

##############################################################################
# Logstash
##############################################################################

resource "aws_security_group" "logstash" {
  name = "logstash"
  description = "Logstash ports with ssh"
  vpc_id = "${aws_vpc.search.id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3333
    to_port = 3333
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9292
    to_port = 9292
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Lumberjack
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "logstash security group"
    stream = "${var.stream_tag}"
  }
}

# logstash instances
module "logstash_nodes" {
  source = "./ec2"

  name = "logstash"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_logstash_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.aws_logstash_instance_type}"
  security_groups = "${concat(aws_security_group.consul_agent.id, ",", aws_security_group.logstash.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
# fixme
  num_nodes = 1
  stream_tag = "${var.stream_tag}"
  public_ip = "false"
}

# logstash route53 A record
resource "aws_route53_record" "logstash" {
   zone_id = "${aws_route53_zone.search.zone_id}"
   name = "logstash"
   type = "A"
   ttl = "30"
   count = 1
   # TODO use elb
   #records = ["${join(",", module.logstash_nodes.private-ips)}"]
   records = ["${module.logstash_nodes.private-ips}"]
}

##############################################################################
# Kibana
##############################################################################

resource "aws_security_group" "kibana" {
  name = "kibana"
  description = "Kibana and nginx ports with ssh"
  vpc_id = "${aws_vpc.search.id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "kibana security group"
    stream = "${var.stream_tag}"
  }
}

# Kibana instances
module "kibana_nodes" {
  source = "./ec2"

  name = "kibana"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_kibana_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_public_a.id}"
  instance_type = "${var.aws_kibana_instance_type}"
  security_groups = "${concat(aws_security_group.consul_agent.id, ",", aws_security_group.kibana.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = 1
  stream_tag = "${var.stream_tag}"
  public_ip = "true"
}
