# Kafka service
resource "aiven_kafka" "tms-demo-kafka" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "business-4"
  service_name = "tms-demo-kafka"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"
  default_acl = false

  kafka_user_config {
    // Enables Kafka Schemas
    schema_registry = true
    kafka_rest = true
    kafka_version = 3.6
    kafka {
      group_max_session_timeout_ms = 70000
      log_retention_bytes = 1000000000
    }
    kafka_authentication_methods {
      certificate = true
      sasl = true
    }
  }
}

// Kafka connect service
resource "aiven_kafka_connect" "tms-demo-kafka-connect" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan = "business-4"
  service_name = "tms-demo-kafka-connect"
  maintenance_window_dow = "monday"
  maintenance_window_time = "10:00:00"

  kafka_connect_user_config {
    kafka_connect {
      consumer_isolation_level = "read_committed"
      scheduled_rebalance_max_delay_ms = 60000
    }
  }
}

// Kafka connect service integration
resource "aiven_service_integration" "tms-demo-connect-integr" {
  project = var.avn_project_id
  integration_type = "kafka_connect"
  source_service_name = aiven_kafka.tms-demo-kafka.service_name
  destination_service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name

  kafka_connect_user_config {
    kafka_connect {
      group_id = "connect_1"
      status_storage_topic = "__connect_1_status"
      offset_storage_topic = "__connect_1_offsets"
      config_storage_topic = "__connect_1_configs"
    }
  }
}

resource "aiven_service_integration" "tms-demo-obs-kafka-integr" {
  project = var.avn_project_id
  integration_type = "metrics"
  source_service_name = aiven_kafka.tms-demo-kafka.service_name
  destination_service_name = aiven_thanos.tms-demo-obs-thanos.service_name
}

resource "aiven_service_integration" "tms-demo-obs-kafka-con-integr" {
  project = var.avn_project_id
  integration_type = "metrics"
  source_service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  destination_service_name = aiven_thanos.tms-demo-obs-thanos.service_name
}
