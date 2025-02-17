output "public_ip" {
    value = aws_instance.k3s-server.public_ip
    description = "EC2 Public IP adresi"
}

output "instance_id" {
    value = aws_instance.k3s-server.id
    description = "EC2 Instance ID"
}
