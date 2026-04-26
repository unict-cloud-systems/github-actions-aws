# Look up the latest Ubuntu 24.04 LTS AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-*"]
  }
}

# Upload the SSH public key so EC2 can inject it into the instance
resource "aws_key_pair" "lab" {
  key_name   = "lab-gitops-key"
  public_key = var.public_key
}

resource "aws_instance" "lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "lab-gitops-aws"
  }
}
