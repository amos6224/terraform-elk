output "private-dns" {
  value = "${join(",", aws_instance.ec2.*.private_dns)}"
}

output "private-ips" {
  value = "${join(",", aws_instance.ec2.*.private_ip)}"
}

output "public-ips" {
  value = "${join(",", aws_instance.ec2.*.public_ip)}"
}
