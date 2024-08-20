resource "aiven_thanos" "tms-demo-obs-thanos" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "business-4"
  service_name = "tms-demo-obs-thanos"

}

output "thanos_obs_host" {
  value = aiven_thanos.tms-demo-obs-thanos.service_host
}