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
  destination_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
}

resource "aiven_service_integration" "flink_to_kafka" {
  project                  = aiven_flink.flink.project
  integration_type         = "flink"
  destination_service_name = aiven_flink.flink.service_name
  source_service_name      = aiven_kafka.tms-demo-kafka.service_name
}

resource "aiven_flink_table" "source" {
  project        = aiven_flink.flink.project
  service_name   = aiven_flink.flink.service_name
  integration_id = aiven_service_integration.flink_to_kafka.integration_id
  table_name     = "source_observations"
  kafka_topic    = aiven_kafka_topic.observations-weather-raw.topic_name
  kafka_startup_mode = "earliest-offset"
  kafka_key_format = "json"
  kafka_key_fields = ["roadStationId"]
  schema_sql     = <<EOF
    `roadStationId` INT,
    `sensorId` INT,
    `value` FLOAT,
    `time` TIMESTAMP,
    WATERMARK FOR `time` AS `time` - INTERVAL '50' SECOND
  EOF
}

resource "aiven_flink_table" "sink" {
  project        = aiven_flink.flink.project
  service_name   = aiven_flink.flink.service_name
  integration_id = aiven_service_integration.flink_to_kafka.integration_id
  table_name     = "sink_observations"
  kafka_topic    = aiven_kafka_topic.observations-weather-flink.topic_name
  kafka_key_format = "json"
  kafka_key_fields = ["roadStationId"]
  schema_sql     = <<EOF
    `roadStationId` INT,
    `sensorId` INT,
    `value` FLOAT,
    `time` TIMESTAMP
  EOF
}

resource "aiven_flink_table" "avg_sink" {
  project        = aiven_flink.flink.project
  service_name   = aiven_flink.flink.service_name
  integration_id = aiven_service_integration.flink_to_kafka.integration_id
  table_name     = "avg_sink_observations"
  kafka_topic    = aiven_kafka_topic.observations-weather-flink-avg.topic_name
  kafka_key_format = "json"
  kafka_key_fields = ["roadStationId"]
  kafka_value_format = "avro"
  schema_sql     = <<EOF
    `roadStationId` INT,
    `sensorId` INT,
    `avgValue` FLOAT,
    `msgCount` BIGINT,
    `windowStart` TIMESTAMP(2),
    `windowEnd` TIMESTAMP(2)
  EOF
}

resource "aiven_flink_job" "filter_job" {
  project      = aiven_flink.flink.project
  service_name = aiven_flink.flink.service_name
  job_name     = "filter_job"
  table_ids = [
    aiven_flink_table.source.table_id,
    aiven_flink_table.sink.table_id
  ]
  statement = <<EOF
    INSERT INTO ${aiven_flink_table.sink.table_name}
    SELECT * FROM ${aiven_flink_table.source.table_name}
    WHERE `sensorId` = 1
  EOF
}

resource "aiven_flink_job" "avg_job" {
  project      = aiven_flink.flink.project
  service_name = aiven_flink.flink.service_name
  job_name     = "avg_job"
  table_ids = [
    aiven_flink_table.source.table_id,
    aiven_flink_table.avg_sink.table_id
  ]
  statement = <<EOF
    INSERT INTO ${aiven_flink_table.avg_sink.table_name}
    SELECT roadStationId, sensorId, AVG(value) as avgValue, COUNT(*) msgCount, window_start, window_end
    FROM TABLE( TUMBLE(TABLE ${aiven_flink_table.source.table_name},
      DESCRIPTOR(time), INTERVAL '15' MINUTES))
    GROUP BY window_start, window_end, GROUPING SETS ((roadStationId, sensorId))
  EOF
}
