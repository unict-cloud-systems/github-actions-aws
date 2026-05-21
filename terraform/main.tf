# Look up the latest Ubuntu 24.04 LTS AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-*"]
  }
}

# Upload the SSH public key so EC2 can inject it into every instance
resource "aws_key_pair" "lab" {
  key_name   = "k8s-lab-key"
  public_key = var.public_key
}

# ── Control-plane node (single-master) ─────────────────────────────────────────
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.control_plane_instance_type
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s.id]

  tags = {
    Name = "k8s-control-plane"
    Role = "control-plane"
  }
}

# ── Worker nodes ───────────────────────────────────────────────────────────────
resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s.id]

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}
