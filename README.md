# lab-gitops-aws

Template repository for **Cloud Systems Lab — Lesson 8: GitOps on AWS with GitHub Actions**.

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