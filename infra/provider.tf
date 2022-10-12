terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = ">= 2.7.1, < 3.0.0"
    }
  }
}

provider "aiven" {
  api_token = var.avn_api_token
}
