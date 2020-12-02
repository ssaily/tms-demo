# Kafka service
resource "aiven_kafka" "tms-demo-kafka" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  plan = "startup-2"
  service_name = "tms-demo-kafka"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"

  kafka_user_config {
    // Enables Kafka Schemas
    schema_registry = true
    kafka_version = "2.6"
    kafka {
      group_max_session_timeout_ms = 70000
      log_retention_bytes = 1000000000
    }
  }
}


