variable "target_region" { // Define a variable for the target region
  description = "Type a desired AWS region to deploy this project"
  type        = string
  default     = "eu-central-1"

  validation { // Validate the target region
    condition     = contains(["us-east-1", "us-east-2", "us-west-1", "us-west-2", "ca-central-1", "sa-east-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "eu-north-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-south-1"], var.target_region)
    error_message = "Invalid region. Allowed regions are: us-east-1, us-east-2, us-west-1, us-west-2, ca-central-1, sa-east-1, eu-central-1, eu-west-1, eu-west-2, eu-west-3, eu-north-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1."
  }
}

provider "aws" { // Define the default AWS provider
  region = var.target_region
}

provider "aws" { // Define the alias AWS provider for the us-east-1 region
  region = "us-east-1"
  alias  = "us-east-1"
}

terraform {      // Define the Terraform backend
  backend "s3" { // Use the S3 backend
    bucket  = "nkterraform"
    key     = "terraform/s4pp.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}