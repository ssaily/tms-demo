resource "aiven_m3db" "tms-demo-m3db" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  plan = "business-8"
  service_name = "tms-demo-m3db"

  m3db_user_config {
        
    namespaces {
      name = "observations"
      type = "unaggregated"
      options {
        retention_options {
          retention_period_duration = "1h"
        }
      }  
    }

    namespaces {
      name = "observations_15m"
      type = "aggregated"
      resolution = "15m"
      options {
        retention_options {
          retention_period_duration = "1d"
        }
      }  
    }

    namespaces {
      name = "observations_1h"
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
  plan = "business-8"
  service_name = "tms-demo-m3a"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"
  
}

resource "aiven_service_integration" "tms-demo-m3-integr" {
  project = var.avn_project_id
  integration_type = "m3aggregator"
  source_service_name = aiven_m3db.tms-demo-m3db.service_name
  destination_service_name = aiven_m3aggregator.tms-demo-m3a.service_name
}
