output "az a instances private dns" {
  value = "`${join(",", module.elastic_a.private-dns)}`"
}

output "az a instances private ips" {
  value = "`${join(",", module.elastic_a.private-ips)}`"
}

output "az b instances private dns" {
  value = "`${join(",", module.elastic_b.private-dns)}`"
}

output "az b instances private ips" {
  value = "`${join(",", module.elastic_b.private-ips)}`"
}
