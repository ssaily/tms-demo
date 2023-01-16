terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = ">= 3.10.0, < 4.0.0"
    }
  }
}

provider "aiven" {
  api_token = var.avn_api_token
}
