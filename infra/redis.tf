resource "aiven_redis" "tms-demo-redis" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc == "true" ? data.aiven_project_vpc.demo-vpc.id : null
  plan = "startup-4"
  service_name = "tms-demo-redis"
}
