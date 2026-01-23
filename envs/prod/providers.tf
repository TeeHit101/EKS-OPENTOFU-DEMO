terraform {
  # Backend configuration is externalized to backend-dev.hcl
  backend "s3" {

    bucket         = "devops-tf-state-123456789012" # Replace with your actual account ID
    key            = "dev2/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-devops-tf-lock"
    encrypt        = true
}

}

provider "aws" {
  region = var.region
}