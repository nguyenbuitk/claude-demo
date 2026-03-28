terraform {
    required_version = ">= 1.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }

    backend "s3" {
        bucket = "claude-demo-terraform-state-028668155772"
        key = "project-1/terraform.tfstate"
        region = "ap-southeast-1"
        dynamodb_table = "claude-demo-terraform-locks"
        encrypt = true
    }
}

provider "aws" {
  region = "ap-southeast-1"
}