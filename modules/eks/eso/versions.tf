terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.52.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.4.1"
    }
  }
}
