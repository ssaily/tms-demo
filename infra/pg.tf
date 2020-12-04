resource "aiven_service" "tms-demo-pg" {
    project = var.avn_project_id
    cloud_name = var.cloud_name
    plan = "startup-4"
    service_name = "tms-demo-pg"
    service_type = "pg"
}

data "aiven_service_user" "pg_admin" {
  project = var.avn_project_id
  service_name = aiven_service.tms-demo-pg.service_name

  # default admin user that is automatically created each Aiven service
  username = "avnadmin"

  depends_on = [
    aiven_service.tms-demo-pg
  ]
}