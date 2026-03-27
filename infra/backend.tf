terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "claude-demo-terraform-state-028668155772"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "claude-demo-terraform-locks"
    encrypt        = true
  }
}