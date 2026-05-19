resource "aws_security_group" "k8s" {
  name        = "k8s-cluster-sg"
  description = "Kubernetes cluster — SSH, K8s API, intra-cluster, NodePort"

  # SSH — needed by Ansible running on the GitHub Actions runner
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s API server — needed by kubectl from the GitHub Actions runner
  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range — needed to reach deployed services from the internet
  ingress {
    description = "NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All intra-cluster traffic (kubelet, etcd, Flannel CNI, kube-proxy, …)
  # Self-referential rule: allow all traffic between instances sharing this SG
  ingress {
    description = "Intra-cluster all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
