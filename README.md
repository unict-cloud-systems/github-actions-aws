# github-actions-aws

Template repository for **Cloud Systems Lab — Lesson 11: Kubernetes on AWS with GitHub Actions**.

> Fork this repo, set secrets in your fork, and the pipeline provisions a 3-node K8s cluster on EC2 and deploys an nginx workload on every merge to `main`.

---

## Repo structure

```
.github/workflows/
  infra.yml      # plan (PR) → provision EC2 cluster → configure K8s (Ansible)
  deploy.yml     # kubectl apply (triggered on k8s/** changes)
  destroy.yml    # manual workflow_dispatch to tear down
terraform/
  providers.tf   # AWS provider + S3 backend (edit bucket name!)
  variables.tf   # region, instance types, worker count, public_key
  main.tf        # AMI lookup, key pair, control-plane + worker EC2 instances
  network.tf     # security group (SSH, K8s API 6443, NodePort 30000-32767, intra-cluster)
  outputs.tf     # control_plane_public_ip, worker_public_ips, ssh_command
ansible/
  00-prerequisites.yml   # swap, kernel modules, sysctl, containerd, kubeadm/kubectl/kubelet
  01-control-plane.yml   # kubeadm init, Flannel CNI, generate join command
  02-workers.yml         # kubeadm join, verify Ready
k8s/
  nginx-deployment.yaml  # sample workload
  nginx-service.yaml     # NodePort 30080
```

---

## One-time setup (do this once per AWS account)

### 1 — Generate SSH key pair

```bash
ssh-keygen -t ed25519 -f id_ed25519 -N ""
# id_ed25519      ← private key  (goes into SSH_PRIVATE_KEY secret)
# id_ed25519.pub  ← public key   (goes into SSH_PUBLIC_KEY secret)
```

Both files are in `.gitignore` — never commit them.

### 2 — Create S3 bucket and DynamoDB table for Terraform state

```bash
BUCKET_NAME="<your-name>-tofu-state"   # must be globally unique

aws s3api create-bucket --bucket "$BUCKET_NAME" \
  --region eu-south-1 \
  --create-bucket-configuration LocationConstraint=eu-south-1

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name tofu-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then edit `terraform/providers.tf` and replace `nics-unict-cloud-systems-tofu-state` with your bucket name.

### 3 — Set up OIDC in AWS IAM

**Add GitHub as an Identity Provider:**

```
IAM Console → Identity Providers → Add provider
  Provider type: OpenID Connect
  Provider URL:  https://token.actions.githubusercontent.com
  Audience:      sts.amazonaws.com
```

**Create an IAM Role** (`github-actions-role`) with these permissions:
- `AmazonEC2FullAccess`
- `AmazonS3FullAccess`
- `AmazonDynamoDBFullAccess` — for state locking
- `AmazonSSMFullAccess` — for KUBECONFIG storage between workflows

**Edit the trust policy** to lock it to your fork:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-USERNAME/github-actions-aws:*"
      }
    }
  }]
}
```

### 4 — Add GitHub Secrets to your fork

```
Settings → Secrets and variables → Actions → New secret

AWS_ROLE_ARN    = arn:aws:iam::ACCOUNT:role/github-actions-role
SSH_PRIVATE_KEY = <contents of id_ed25519>
SSH_PUBLIC_KEY  = <contents of id_ed25519.pub>
```

---

## Cost warning

⚠️ **K8s requires instances larger than free tier:**

| Node | Instance | vCPU | RAM | Cost (eu-south-1) |
|------|----------|------|-----|-------------------|
| control-plane | t3.medium | 2 | 4 GB | ~$0.047/h |
| worker ×2 | t3.small | 2 | 2 GB | ~$0.023/h each |

**Always run the `Destroy K8s Cluster` workflow at the end of the lab.**

---

## Quick start

```bash
# Clone your fork
git clone git@github.com:YOUR-USERNAME/github-actions-aws.git
cd github-actions-aws

# Edit the bucket name in terraform/providers.tf
# Push to main → watch the Actions tab
git add terraform/providers.tf
git commit -m "chore: set S3 backend bucket"
git push origin main
```


> Fork this repo, set secrets in your fork, and the pipeline provisions an EC2 instance on every merge to `main`.

---

## Repo structure

```
.github/workflows/
  infra.yml        # plan on PR, apply on merge to main
  configure.yml    # install Docker via Ansible (triggered after infra)
  destroy.yml      # manual workflow_dispatch to tear down
terraform/
  providers.tf     # AWS provider + S3 backend (edit bucket name!)
  variables.tf     # region, instance_type, public_key
  main.tf          # AMI lookup, aws_key_pair, aws_instance
  network.tf       # security group (SSH only)
  outputs.tf       # instance_public_ip, ssh_command
ansible/
  install_docker.yml
```

---

## One-time setup (do this once per AWS account)

### 1 — Generate SSH key pair

```bash
ssh-keygen -t ed25519 -f id_ed25519 -N ""
# id_ed25519      ← private key (goes into SSH_PRIVATE_KEY secret)
# id_ed25519.pub  ← public key  (goes into SSH_PUBLIC_KEY secret)
```

Both files are in `.gitignore` — never commit them.

### 2 — Create S3 bucket and DynamoDB table for Terraform state

```bash
BUCKET_NAME="<your-name>-tofu-state"   # must be globally unique

aws s3api create-bucket --bucket "$BUCKET_NAME" --region us-east-1

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name tofu-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then edit `terraform/providers.tf` and replace `CHANGE_ME-tofu-state` with your bucket name.

### 3 — Set up OIDC in AWS IAM

**Add GitHub as an Identity Provider:**

```
IAM Console → Identity Providers → Add provider
  Provider type: OpenID Connect
  Provider URL:  https://token.actions.githubusercontent.com
  Audience:      sts.amazonaws.com
```

**Create an IAM Role** (`github-actions-role`):

```
IAM Console → Roles → Create role
  Trusted entity: Web identity
  Identity provider: token.actions.githubusercontent.com
  Audience: sts.amazonaws.com
  Permissions: AmazonEC2FullAccess, AmazonS3FullAccess, AmazonDynamoDBFullAccess
```

**Edit the trust policy** to lock it to your fork:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-USERNAME/github-actions-aws:*"
      }
    }
  }]
}
```

Copy the Role ARN — you'll need it in the next step.

### 4 — Fork this repo and set secrets

Fork this repo on GitHub, then go to your fork:

```
Settings → Secrets and variables → Actions → New repository secret

AWS_ROLE_ARN      = arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-role
SSH_PRIVATE_KEY   = <paste contents of id_ed25519>
SSH_PUBLIC_KEY    = <paste contents of id_ed25519.pub>
```

### 5 — Initialise the backend locally (once)

```bash
cd terraform
tofu init   # migrates/confirms S3 backend
```

---

## The GitOps loop

```
feature branch → PR → tofu plan posted as comment → review → merge to main
  → apply job → EC2 created → configure job → Docker installed
```

**Make a change:**

```bash
git checkout -b feat/my-change
# edit terraform/variables.tf, e.g. change instance_type
git add terraform/variables.tf
git commit -m "chore: change instance type"
git push origin feat/my-change
# open PR on GitHub → read the plan comment → merge
```

**Rollback:**

```bash
git revert HEAD
git push origin main
# pipeline runs tofu apply → reverts the infrastructure change
```

**Destroy (end of lab):**

```
GitHub → Actions → Destroy AWS EC2 → Run workflow
```

> ⚠️ Always destroy at the end of the lab. Free tier is 750 h/month for t2.micro.