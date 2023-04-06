terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = ">= 4.2.0"
    }
  }
}

provider "aiven" {
  api_token = var.avn_api_token
}
