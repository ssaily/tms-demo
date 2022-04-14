
terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = "2.7.1"
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
  project    = data.aiven_project.demo-project.project
  cloud_name = var.cloud_name
}