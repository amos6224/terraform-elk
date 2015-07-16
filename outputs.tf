output "public nat a" {
  value = "${aws_instance.nat_a.public_ip}"
}

output "private nat a" {
  value = "${aws_instance.nat_a.private_ip}"
}

output "elasticsearch private ips a" {
  value = "${module.elastic_nodes_a.private-ips}"
}

output "elasticsearch private ips b" {
  value = "${module.elastic_nodes_b.private-ips}"
}

output "logstash private ips" {
  value = "${module.logstash_nodes.private-ips}"
}

output "kibana private ips" {
  value = "${module.kibana_nodes.private-ips}"
}

output "kibana public ips" {
  value = "${module.kibana_nodes.public-ips}"
}

output "consul server private ips a" {
  value = "${module.consul_servers_a.private-ips}"
}

output "consul server private ips b" {
  value = "${module.consul_servers_b.private-ips}"
}

output "bastion server public ips a"{
  value = "${module.bastion_servers_a.public-ips}"
}

output "bastion server public ips b"{
  value = "${module.bastion_servers_b.public-ips}"
}
