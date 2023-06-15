resource "aiven_m3db" "tms-demo-obs-m3db" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "business-8"
  service_name = "tms-demo-obs-m3db"

  m3db_user_config {
    m3db_version = 1.5
    namespaces {
      name = "metrics"
      type = "unaggregated"
      options {
        retention_options {
          retention_period_duration = "30d"
        }
      }
    }

    namespaces {
      name = "metrics_1h"
      type = "aggregated"
      resolution = "1h"
      options {
        retention_options {
          retention_period_duration = "356d"
        }
      }
    }
  }
}

resource "aiven_m3aggregator" "tms-demo-m3a" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "business-8"
  service_name = "tms-demo-m3a"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"

  m3aggregator_user_config {
    m3aggregator_version = 1.5
  }

}

resource "aiven_service_integration" "tms-demo-obs-m3-integr" {
  project = var.avn_project_id
  integration_type = "m3aggregator"
  source_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
  destination_service_name = aiven_m3aggregator.tms-demo-m3a.service_name
}

output "m3db_obs_host" {
  value = aiven_m3db.tms-demo-obs-m3db.service_host
}