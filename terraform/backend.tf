# remote backend
terraform {
  backend "s3" {
    bucket         = "groupb-terraform-009"
    key            = "tfstate-upgrade/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
  }
}