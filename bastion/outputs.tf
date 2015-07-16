output "public-ips" {
  value = "${join(",", aws_instance.bastion.*.public_ip)}"
}
