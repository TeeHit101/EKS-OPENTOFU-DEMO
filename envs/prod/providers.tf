terraform {
  # Backend configuration is externalized to backend-dev.hcl
  backend "s3" {

    bucket         = "devops-lia-team-visma-tf-state-660483628600"
    key            = "dev2/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-devops-team-lia-lock"
    encrypt        = true
}

}

provider "aws" {
  region = var.region
}
