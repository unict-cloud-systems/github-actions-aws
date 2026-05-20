variable "aws_region" {
  type    = string
  default = "eu-south-1"
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for K8s control plane - kubeadm needs >= 2 vCPU, 2 GB RAM (t3.small = 2 vCPU 2 GB, free-tier eligible)"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of K8s worker nodes"
  type        = number
  default     = 4
}

variable "worker_instance_type" {
  description = "EC2 instance type for K8s workers — kubeadm needs >= 2 vCPU, 2 GB RAM (t3.small = 2 vCPU 2 GB)"
  type        = string
  default     = "t3.small"
}

variable "public_key" {
  description = "SSH public key content (passed via TF_VAR_public_key from the SSH_PUBLIC_KEY GitHub Secret)"
  type        = string
  sensitive   = true
}
