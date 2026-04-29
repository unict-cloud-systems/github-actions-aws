variable "aws_region" {
  type    = string
  default = "eu-south-1"
}

variable "instance_type" {
  description = "EC2 instance type — t2.micro is Free Tier eligible"
  type        = string
  default     = "t3.small"
}

variable "public_key" {
  description = "SSH public key content (passed via TF_VAR_public_key from the SSH_PUBLIC_KEY GitHub Secret)"
  type        = string
  sensitive   = true
}
