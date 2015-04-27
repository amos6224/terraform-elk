output "private-dns" {
  value = "`${var.name}_${join(",", aws_instance.logstash.*.private_dns)}`"
}

output "private-ips" {
  value = "`${join(",", aws_instance.logstash.*.private_ip)}`"
}
