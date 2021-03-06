resource "aiven_m3db" "tms-demo-m3db" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  plan = "business-8"
  service_name = "tms-demo-m3db"

  m3db_user_config {
    m3db_version = "1.0"

    namespaces {
      name = "observations"
      type = "unaggregated"
    }
  }
}

