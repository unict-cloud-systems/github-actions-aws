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
    bucket         = "CHANGE_ME-tofu-state"   # globally unique name
    key            = "lab/ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tofu-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
