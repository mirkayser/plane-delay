terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.39"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
