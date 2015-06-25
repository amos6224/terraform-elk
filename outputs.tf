output "public nat a" {
  value = "${aws_instance.nat_a.public_ip}"
}

output "private nat a" {
  value = "${aws_instance.nat_a.private_ip}"
}

output "elasticsearch private dns a" {
  value = "${join(",", module.elastic_nodes_a.private-dns)}"
}

output "elasticsearch private ips a" {
  value = "${join(",", module.elastic_nodes_a.private-ips)}"
}

output "elasticsearch private dns b" {
  value = "${join(",", module.elastic_nodes_b.private-dns)}"
}

output "elasticsearch private ips b" {
  value = "${join(",", module.elastic_nodes_b.private-ips)}"
}

output "logstash private dns" {
  value = "${join(",", module.logstash_nodes.private-dns)}"
}

output "logstash private ips" {
  value = "${join(",", module.logstash_nodes.private-ips)}"
}

output "kibana private dns" {
  value = "${join(",", module.kibana_nodes.private-dns)}"
}

output "kibana private ips" {
  value = "${join(",", module.kibana_nodes.private-ips)}"
}

output "kibana public ips" {
  value = "${join(",", module.kibana_nodes.public-ips)}"
}

output "consul server private dns a" {
  value = "${join(",", module.consul_servers_a.private-dns)}"
}

output "consul server private ips a" {
  value = "${join(",", module.consul_servers_a.private-ips)}"
}

output "consul server public ips a" {
  value = "${join(",", module.consul_servers_a.public-ips)}"
}

output "consul server private dns b" {
  value = "${join(",", module.consul_servers_a.private-dns)}"
}

output "consul server private ips b" {
  value = "${join(",", module.consul_servers_a.private-ips)}"
}

output "consul server public ips b" {
  value = "${join(",", module.consul_servers_a.public-ips)}"
}
