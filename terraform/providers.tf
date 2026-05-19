terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — bucket must exist before running tofu init
  # Create it with the commands in the README, then replace CHANGE_ME below.
  backend "s3" {
    bucket         = "nics-unict-cloud-systems-tofu-state"   # globally unique name
    key            = "lab/k8s/terraform.tfstate"
    region         = "eu-south-1"
    dynamodb_table = "tofu-state-lock"  # must exist before running tofu init
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
