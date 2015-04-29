output "private-dns" {
  value = "${join(",", aws_instance.logstash.*.private_dns)}"
}

output "private-ips" {
  value = "${join(",", aws_instance.logstash.*.private_ip)}"
}
