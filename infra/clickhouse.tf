resource "aiven_clickhouse" "tms-demo-ch" {
  project                 = var.avn_project_id
  cloud_name              = var.cloud_name
  project_vpc_id          = var.use_cloud_vpc == "true" ? data.aiven_project_vpc.demo-vpc[0].id : null
  plan                    = "business-16"
  service_name            = "tms-demo-ch"
  maintenance_window_dow  = "monday"
  maintenance_window_time = "10:00:00"
  depends_on = [
    aiven_kafka_topic.observations-weather-raw
  ]
}

resource "aiven_service_integration" "ch-obs-integr" {
  project                  = var.avn_project_id
  integration_type         = "metrics"
  source_service_name      = aiven_clickhouse.tms-demo-ch.service_name
  destination_service_name = aiven_m3db.tms-demo-obs-m3db.service_name
}

resource "aiven_service_integration" "ch-kafka-integr" {
  project                  = var.avn_project_id
  integration_type         = "clickhouse_kafka"
  source_service_name      = aiven_kafka.tms-demo-kafka.service_name
  destination_service_name = aiven_clickhouse.tms-demo-ch.service_name

  clickhouse_kafka_user_config {
    tables {
        name = "observations"
        data_format = "AvroConfluent"
        group_name = "observations"
        # (number of CH nodes * num_consumers = total no.of members in consumer group)
        num_consumers = 1
        topics {
            name = aiven_kafka_topic.observations-weather-enriched.topic_name
        }
        columns {
            name = "roadStationId"
            type = "UInt16"
        }
        columns {
            name = "sensorId"
            type = "UInt8"
        }
        columns {
            name = "sensorName"
            type = "LowCardinality(String)"
        }
        columns {
            name = "sensorValue"
            type = "Float64"
        }
        columns {
            name = "sensorUnit"
            type = "LowCardinality(String)"
        }
        columns {
            name = "measuredTime"
            type = "DateTime64(3)"
        }
        columns {
            name = "latitude"
            type = "Float64"
        }
        columns {
            name = "longitude"
            type = "Float64"
        }
        columns {
            name = "geohash"
            type = "String"
        }
    }
    tables {
        name = "observations_multivariate"
        data_format = "AvroConfluent"
        group_name = "observations_multivariate"
        # (number of CH nodes * num_consumers = total no.of members in consumer group)
        num_consumers = 1
        topics {
            name = aiven_kafka_topic.observations-weather-multivariate.topic_name
        }
        columns {
            name = "roadStationId"
            type = "UInt16"
        }
        columns {
            name = "measuredTime"
            type = "DateTime"
        }
        columns {
            name = "measurements"
            type = "Map(LowCardinality(String), Float64)"
        }
        columns {
            name = "geohash"
            type = "String"
        }
    }
  }
}

resource "aiven_clickhouse_database" "ch-observations-db" {
  project                 = var.avn_project_id
  service_name            = aiven_clickhouse.tms-demo-ch.service_name
  name                    = "weather"
}
