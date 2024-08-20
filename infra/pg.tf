resource "aiven_pg" "tms-demo-pg" {
    project = var.avn_project_id
    cloud_name = var.cloud_name
    project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
    plan = "startup-4"
    service_name = "tms-demo-pg"
}

resource "aiven_service_integration" "tms-demo-obs-pg-integr" {
  project = var.avn_project_id
  integration_type = "metrics"
  source_service_name = aiven_pg.tms-demo-pg.service_name
  destination_service_name = aiven_thanos.tms-demo-obs-thanos.service_name
}

data "aiven_pg_user" "pg_admin" {
  project = var.avn_project_id
  service_name = aiven_pg.tms-demo-pg.service_name

  # default admin user that is automatically created for each Aiven service
  username = "avnadmin"
}