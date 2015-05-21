provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
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
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options" "search" {
  domain_name = "search.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Name = "search internal"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_search" {
  vpc_id = "${aws_vpc.search.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.search.id}"
}

##############################################################################
# VPC Peering
##############################################################################

resource "aws_vpc_peering_connection" "search_to_parent" {
  peer_owner_id = "${var.aws_peer_owner_id}"
  peer_vpc_id = "${var.aws_parent_vpc_id}"
  vpc_id = "${aws_vpc.search.id}"

  tags {
    Name = "search to parent peering"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Subnets
##############################################################################

resource "aws_subnet" "search_a" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${var.aws_subnet_cidr_a}"

  tags {
    Name = "A_Search_VPC"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "search" {
  vpc_id = "${aws_vpc.search.id}"

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.search_to_parent.id}"
    cidr_block = "${var.aws_parent_vpc_cidr}"
  }

  tags {
    Name = "elastic peered route table"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "search_a" {
  subnet_id = "${aws_subnet.search_a.id}"
  route_table_id = "${aws_route_table.search.id}"
}

resource "aws_subnet" "search_b" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${var.aws_subnet_cidr_b}"

  tags {
    Name = "B_Search_VPC"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "search_b" {
  subnet_id = "${aws_subnet.search_b.id}"
  route_table_id = "${aws_route_table.search.id}"
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

module "consul_servers_a" {
  source = "./consul_server"

  name = "a"
  region = "${var.aws_region}"
  #fixme
  ami = "ami-69631053"
  subnet = "${aws_subnet.search_a.id}"
  #fixme
  instance_type = "t2.small"
  security_groups = "${concat(aws_security_group.consul_server.id, ",", aws_security_group.consul_agent.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  #fixme (both az odd number)
  num_nodes = "2"
  stream_tag = "${var.stream_tag}"
}

module "consul_servers_b" {
  source = "./consul_server"

  name = "b"
  region = "${var.aws_region}"
  #fixme
  ami = "ami-69631053"
  subnet = "${aws_subnet.search_b.id}"
  #fixme
  instance_type = "t2.small"
  security_groups = "${concat(aws_security_group.consul_server.id, ",", aws_security_group.consul_agent.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  #fixme
  num_nodes = "1"
  stream_tag = "${var.stream_tag}"
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
    to_port = 9399
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
    Stream = "${var.stream_tag}"
  }
}

module "elastic_nodes_a" {
  source = "./elastic"

  name = "a"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.aws_instance_type}"
  elastic_group = "${aws_security_group.elastic.id}"
  security_groups = "${concat(aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_a}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

# elastic instances subnet a
module "elastic_nodes_b" {
  source = "./elastic"

  name = "b"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_b.id}"
  instance_type = "${var.aws_instance_type}"
  elastic_group = "${aws_security_group.elastic.id}"
  security_groups = "${concat(aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_b}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

# the instances over SSH and logstash ports
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
    Stream = "${var.stream_tag}"
  }
}

# logstash instances
module "logstash_nodes" {
  source = "./ec2"

  name = "logstash"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_logstash_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.aws_instance_type}"
  security_groups = "${concat(aws_security_group.logstash.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = 1
  stream_tag = "${var.stream_tag}"
}

#resource "aws_route53_zone" "search" {
#  name = "${var.domain_name}"
#}

# create hosted zone
# this should be private private
# zone_id = "${aws_route53_zone.search.zone_id}"
resource "aws_route53_record" "logstash" {
   zone_id = "${var.hosted_zone_id}"
   name = "logstash"
   type = "A"
   ttl = "30"
   records = ["${join(",", module.logstash_nodes.private-ips)}"]
}

# the instances over SSH and logstash ports
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
    Stream = "${var.stream_tag}"
  }
}

# Kibana instances
module "kibana_nodes" {
  source = "./ec2"

  name = "kibana"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_kibana_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.aws_kibana_instance_type}"
  security_groups = "${concat(aws_security_group.kibana.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = 1
  stream_tag = "${var.stream_tag}"
}
