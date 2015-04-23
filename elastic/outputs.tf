output "private-dns" {
  value = "`${var.name}_${join(",", aws_instance.elastic.*.private_dns)}`"
}

output "private-ips" {
  value = "`${join(",", aws_instance.elastic.*.private_ip)}`"
}
