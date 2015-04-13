output "instances private dns" {
  value = "`${join(",", module.elastic.private-dns)}`"
}

output "instances private ips" {
  value = "`${join(",", module.elastic.private-ips)}`"
}
