
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

data "aiven_project" "demo-project" {
  project = var.avn_project_id
}

data "aiven_project_vpc" "demo-vpc" {
  count = var.use_cloud_vpc ? 1 : 0
  project    = data.aiven_project.demo-project.project
  cloud_name = var.cloud_name
}