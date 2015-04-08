output "instances private dns" {
  value = "`${join(",", aws_instance.elastic.*.private_dns)}`"
}

output "instances private ip" {
  value = "`${join(",", aws_instance.elastic.*.private_ip)}`"
}

#output "public ip" {
#  value = "${aws_instance.elastic.public_ip}"
#}
