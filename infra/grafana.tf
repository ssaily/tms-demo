resource "aiven_grafana" "tms-demo-grafana" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan         = "startup-4"
  service_name = "tms-demo-grafana"
  grafana_user_config {
    public_access {
      grafana = true
    }
  }
}

resource "aiven_service_integration" "tms-demo-grafana-datasource" {
  project = var.avn_project_id
  integration_type = "datasource"
  source_service_name = aiven_grafana.tms-demo-grafana.service_name
  destination_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
}

resource "aiven_service_integration" "tms-demo-grafana-dashboard" {
  project = var.avn_project_id
  integration_type = "dashboard"
  source_service_name = aiven_grafana.tms-demo-grafana.service_name
  destination_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
}