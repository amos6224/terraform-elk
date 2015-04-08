output "instances private dns" {
  value = "`${join(",", aws_instance.elastic.*.private_dns)}`"
}

output "instances private ips" {
  value = "`${join(",", aws_instance.elastic.*.private_ip)}`"
}
