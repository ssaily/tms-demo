resource "aiven_flink" "flink" {
  project = var.avn_project_id
  cloud_name = var.cloud_name
  project_vpc_id = var.use_cloud_vpc == "true" ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan         = "business-8"
  service_name = "tms-demo-flink"
}

resource "aiven_service_integration" "tms-demo-obs-flink-integr" {
  project = aiven_flink.flink.project
  integration_type = "metrics"
  source_service_name = aiven_flink.flink.service_name
  destination_service_name = aiven_thanos.tms-demo-obs-thanos.service_name
}

resource "aiven_service_integration" "flink_to_kafka" {
  project                  = aiven_flink.flink.project
  integration_type         = "flink"
  destination_service_name = aiven_flink.flink.service_name
  source_service_name      = aiven_kafka.tms-demo-kafka.service_name
}

resource "aiven_flink_application" "weather" {
  project = aiven_flink.flink.project
  service_name = aiven_flink.flink.service_name
  name = "weather"
}

resource "aiven_flink_application_version" "demo-flink-application" {
  project                  = aiven_flink.flink.project
  service_name             = aiven_flink.flink.service_name
  application_id           = aiven_flink_application.weather.application_id
  statement      = templatefile("../streamprocessing/flink/statement.sql", {} )

  source {
    create_table   = templatefile("../streamprocessing/flink/source_table.sql", {
      sr_uri = "https://${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}",
      sr_user_info = "${data.aiven_kafka_user.kafka_admin.username}:${data.aiven_kafka_user.kafka_admin.password}",
      src_topic = aiven_kafka_topic.observations-weather-enriched.topic_name
    } )
    integration_id = aiven_service_integration.flink_to_kafka.integration_id
  }

  sink {
    create_table   = templatefile("../streamprocessing/flink/sink_table.sql", {
      sr_uri = "https://${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}",
      sr_user_info = "${data.aiven_kafka_user.kafka_admin.username}:${data.aiven_kafka_user.kafka_admin.password}",
      sink_topic = aiven_kafka_topic.observations-weather-flink-avg.topic_name
    } )
    integration_id = aiven_service_integration.flink_to_kafka.integration_id
  }
}

resource "aiven_flink_application" "statistics" {
  project = aiven_flink.flink.project
  service_name = aiven_flink.flink.service_name
  name = "statistics"
}

resource "aiven_flink_application_version" "stats-flink-application" {
  project                  = aiven_flink.flink.project
  service_name             = aiven_flink.flink.service_name
  application_id           = aiven_flink_application.statistics.application_id
  statement      = templatefile("../streamprocessing/flink/stats.sql", {} )

  source {
    create_table   = templatefile("../streamprocessing/flink/source_table.sql", {
      sr_uri = "https://${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}",
      sr_user_info = "${data.aiven_kafka_user.kafka_admin.username}:${data.aiven_kafka_user.kafka_admin.password}",
      src_topic = aiven_kafka_topic.observations-weather-enriched.topic_name
    } )
    integration_id = aiven_service_integration.flink_to_kafka.integration_id
  }

  sink {
    create_table   = templatefile("../streamprocessing/flink/stats_sink_table.sql", {
      sr_uri = "https://${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}",
      sr_user_info = "${data.aiven_kafka_user.kafka_admin.username}:${data.aiven_kafka_user.kafka_admin.password}",
      sink_topic = aiven_kafka_topic.observations-weather-flink-stats.topic_name
    } )
    integration_id = aiven_service_integration.flink_to_kafka.integration_id
  }
}