# ── Network Load Balancer for ingress-nginx ────────────────────────────────────
#
# Stage 2 — copy this file to terraform/ after the cluster is bootstrapped:
#
#   cp ingress/terraform/nlb.tf terraform/nlb.tf
#   cp ingress/k8s/nginx-service.yaml k8s/nginx-service.yaml   # NodePort → ClusterIP
#   cp ingress/k8s/nginx-ingress.yaml k8s/nginx-ingress.yaml
#   git add terraform/nlb.tf k8s/
#   git commit -m "feat: add ingress-nginx + NLB"
#   git push origin main
#
# What happens on push:
#   • infra.yml  — tofu apply creates the NLB targeting workers on NodePort 30080
#   • deploy.yml — detects Ingress resources, installs ingress-nginx (NodePort 30080),
#                  switches nginx Service to ClusterIP, applies the Ingress rule

# ── Discover the default VPC and its subnets ───────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Network Load Balancer ──────────────────────────────────────────────────────
resource "aws_lb" "ingress" {
  name               = "k8s-ingress-nlb"
  load_balancer_type = "network"
  internal           = false
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "k8s-ingress-nlb"
  }
}

# ── Target group — workers on the fixed ingress-nginx NodePort ─────────────────
resource "aws_lb_target_group" "ingress_http" {
  name     = "k8s-ingress-http"
  port     = 30080
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    protocol            = "TCP"
    port                = "30080"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "workers" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.ingress_http.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 30080
}

# ── Listener: port 80 → ingress-nginx ─────────────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress_http.arn
  }
}

# ── Output ─────────────────────────────────────────────────────────────────────
output "nlb_dns_name" {
  description = "NLB DNS — curl http://<nlb_dns_name> reaches the app via ingress"
  value       = aws_lb.ingress.dns_name
}
