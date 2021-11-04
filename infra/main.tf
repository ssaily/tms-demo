
terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = "2.3.0"
    }
  }
}

provider "aiven" {
  api_token = var.avn_api_token
}
