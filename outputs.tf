output "az a instances private dns" {
  value = "${join(",", module.elastic_nodes_a.private-dns)}"
}

output "az a instances private ips" {
  value = "${join(",", module.elastic_nodes_a.private-ips)}"
}

output "az b instances private dns" {
  value = "${join(",", module.elastic_nodes_b.private-dns)}"
}

output "az b instances private ips" {
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
