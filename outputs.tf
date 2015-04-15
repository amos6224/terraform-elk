output "instances public dns" {
  value = "`${join(",", aws_instance.elastic.*.public_dns)}`"
}

output "instances public ips" {
  value = "`${join(",", aws_instance.elastic.*.public_ip)}`"
}
