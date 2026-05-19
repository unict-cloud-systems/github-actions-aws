output "control_plane_public_ip" {
  description = "Public IP of the K8s control-plane node"
  value       = aws_instance.control_plane.public_ip
}

output "worker_public_ips" {
  description = "Public IPs of K8s worker nodes"
  value       = [for w in aws_instance.worker : w.public_ip]
}

output "ssh_command" {
  description = "SSH command to connect to the control-plane node"
  value       = "ssh -i id_ed25519 ubuntu@${aws_instance.control_plane.public_ip}"
}
