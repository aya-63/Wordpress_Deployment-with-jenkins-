output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.app_lb.dns_name
}
output "instance_private_ips" {
  description = "Private IPs of the EC2 instances"
  value = [
    aws_instance.web_instance_1.private_ip,
    aws_instance.web_instance_2.private_ip
  ]
}

output "vpc_peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.peer.id
}
