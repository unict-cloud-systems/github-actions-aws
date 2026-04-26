output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.lab.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i id_ed25519 ubuntu@${aws_instance.lab.public_ip}"
}
