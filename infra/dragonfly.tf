resource "aiven_dragonfly" "tms-demo-dragonfly" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "startup-4"
  service_name = "tms-demo-dragonfly"
}

resource "aiven_service_integration" "tms-demo-obs-df-integr" {
  project = var.avn_project_id
  integration_type = "metrics"
  source_service_name = aiven_dragonfly.tms-demo-dragonfly.service_name
  destination_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
}