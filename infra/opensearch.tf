# Opensearch service
resource "aiven_opensearch" "tms-demo-os" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "business-4"
  service_name = "tms-demo-os"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"
}

resource "aiven_service_integration" "tms-demo-obs-os-integr" {
  project = var.avn_project_id
  integration_type = "metrics"
  source_service_name = aiven_opensearch.tms-demo-os.service_name
  destination_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
}

# Opensearch user
resource "aiven_service_user" "os-user" {
  project = var.avn_project_id
  service_name = aiven_opensearch.tms-demo-os.service_name
  username = "test-user1"
}
