# Kafka topics

resource "aiven_kafka_topic" "observations-weather-raw" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.raw"
  partitions = 20
  replication = 2
  config {
    retention_ms = 259200000
    cleanup_policy = "delete"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "observations-weather-flink-avg" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.flink-avg-avro"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "observations-weather-flink-stats" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.flink-stats"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "observations-weather-flink-jar-out" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.flink-jar-out"
  partitions = 20
  replication = 2
  config {
    retention_ms = 259200000
    cleanup_policy = "delete"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "observations-weather-multivariate" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.multivariate"
  partitions = 20
  replication = 2
  config {
    retention_ms = 259200000
    cleanup_policy = "delete"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "observations-weather-enriched" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.enriched"
  partitions = 20
  replication = 2
  config {
    retention_ms = 1814400000
    cleanup_policy = "delete"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "observations-weather-avg-air-temperature" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.weather.avg-air-temperature"
  partitions = 20
  replication = 2
  config {
    retention_ms = 1814400000
    cleanup_policy = "delete"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "stations-weather" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms.public.weather_stations"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "stations-traffic" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms.public.traffic_stations"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "stations-weather-2" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms2.public.weather_stations"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "stations-traffic-2" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms2.public.traffic_stations"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "sensors-weather" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms.public.weather_sensors"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "sensors-weather-2" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms2.public.weather_sensors"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "sensors-traffic" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms.public.traffic_sensors"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "sensors-traffic-2" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms2.public.traffic_sensors"
  partitions = 20
  replication = 2
  config {
    cleanup_policy = "compact"
    min_insync_replicas = 2
  }
}


resource "aiven_kafka_topic" "observations-traffic-raw" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "observations.traffic.raw"
  partitions = 20
  replication = 2
  config {
    retention_ms = 259200000
    cleanup_policy = "delete"
    min_insync_replicas = 2
  }
}

resource "aiven_kafka_topic" "dlq-sink" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  topic_name = "tms.dlq_sink"
  partitions = 20
  replication = 2
  config {
    retention_ms = 259200000
    cleanup_policy = "delete"
    min_insync_replicas = 1
  }
}