data "aiven_service_component" "schema_registry" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  component = "schema_registry"
  route = "dynamic"
}

data "aiven_service_component" "tms_pg" {
    project = var.avn_project_id
    service_name = aiven_pg.tms-demo-pg.service_name
    component = "pg"
    route = "dynamic"
}

locals {
  schema_registry_uri = "https://${data.aiven_kafka_user.kafka_admin.username}:${data.aiven_kafka_user.kafka_admin.password}@${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}"
}

resource "aiven_kafka_connector" "kafka-pg-cdc-stations" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "kafka-pg-cdc-stations"

  config = {
    "_aiven.restart.on.failure": "true",
    "key.converter" : "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "name": "kafka-pg-cdc-stations",
    "slot.name": "station_repl_slot",
    "publication.name": "station_publication",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",
    "database.server.name": "pg-stations",
    "table.whitelist": "public.weather_stations",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "transforms": "unwrap,insertKey,extractKey",
    "transforms.unwrap.type":"io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones":"false",
    "transforms.insertKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.insertKey.fields":"roadstationid",
    "transforms.extractKey.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field":"roadstationid",
    "include.schema.changes": "false"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

resource "aiven_kafka_connector" "kafka-pg-cdc-stations-2" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "kafka-pg-cdc-stations-2"

  config = {
    "_aiven.restart.on.failure": "true",
    "key.converter" : "io.confluent.connect.avro.AvroConverter",
    "key.converter.schema.registry.url": local.schema_registry_uri,
    "key.converter.basic.auth.credentials.source": "URL",
    "key.converter.schemas.enable": "true",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "name": "kafka-pg-cdc-stations-2",
    "slot.name": "station2_repl_slot",
    "publication.name": "station_publication",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",
    "database.server.name": "pg-stations-2",
    "table.whitelist": "public.weather_stations_2",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "transforms":"route",
    "transforms.route.regex": "pg-stations-2.public.weather_stations_2",
    "transforms.route.replacement": "weather_stations",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "include.schema.changes": "false"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

resource "aiven_kafka_connector" "bq-sink" {
  count = "${var.bq_project != "" ? 1 : 0}"
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "bq-sink"
  config = {
    "_aiven.restart.on.failure": "true",
    "name": "bq-sink",
    "connector.class": "com.wepay.kafka.connect.bigquery.BigQuerySinkConnector",
    "key.converter" : "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "topics": aiven_kafka_topic.observations-weather-multivariate.topic_name,
    # "topics.regex": "observations.weather.(?!avg-air-temperature)(?!flink)(?!flink-avg-avro)(?!enriched)(?!raw)"
    "project": var.bq_project,
    "keySource": "JSON",
    "keyfile": var.bq_key,
    "defaultDataset": "tms_demo_dataset",
    "autoCreateTables": "true",
    "bigQueryPartitionDecorator": "false",
    "bigQueryMessageTimePartitioning": "true",
    "timestampPartitionFieldName": "measuredTime",
    "kafkaDataFieldName": "kafka_metadata",
    "allowNewBigQueryFields": "true",
    "allowBigQueryRequiredFieldRelaxation": "true",
    "allowSchemaUnionization": "false",
    "deleteEnabled": "false",
    "mergeIntervalMs": "5000",
    "transforms": "tableChange, timestampConverter",
    "transforms.timestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.timestampConverter.field": "measuredTime",
    "transforms.timestampConverter.target.type": "unix",
    "transforms.tableChange.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.tableChange.regex": ".*",
    "transforms.tableChange.replacement": "observation"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

resource "aiven_kafka_connector" "kafka-pg-cdc-sensors" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "kafka-pg-cdc-sensors"

  config = {
    "_aiven.restart.on.failure": "true",
    "key.converter" : "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "name": "kafka-pg-cdc-sensors",
    "slot.name": "sensor_repl_slot",
    "publication.name": "station_publication",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",
    "database.server.name": "pg-sensors",
    "table.whitelist": "public.weather_sensors",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "transforms": "unwrap,insertKey,extractKey",
    "transforms.unwrap.type":"io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones":"false",
    "transforms.insertKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.insertKey.fields":"sensorid",
    "transforms.extractKey.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field":"sensorid",
    "include.schema.changes": "false"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

resource "aiven_kafka_connector" "kafka-redis-sink" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "kafka-redis-sink"
  config = {
    "name": "kafka-redis-sink",
    "_aiven.restart.on.failure": "true",
    "connector.class": "com.datamountaineer.streamreactor.connect.redis.sink.RedisSinkConnector",
    "key.converter" : "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "topics": aiven_kafka_topic.observations-weather-enriched.topic_name,
    "connect.redis.host": aiven_redis.tms-demo-redis.service_host,
    "connect.redis.port": aiven_redis.tms-demo-redis.service_port,
    "connect.redis.password": aiven_redis.tms-demo-redis.service_password,
    "connect.redis.ssl.enabled": "true",
    "transforms": "extractTopic, insertField, resetTopic",
    "transforms.extractTopic.type":"io.aiven.kafka.connect.transforms.ExtractTopic$Key",
    "transforms.insertField.type":"org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.insertField.topic.field":"rsid",
    "transforms.resetTopic.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.resetTopic.regex": "(.*)"
    "transforms.resetTopic.replacement": "${aiven_kafka_topic.observations-weather-enriched.topic_name}"
    "connect.redis.kcql": <<EOF
      INSERT INTO cache- SELECT sensorName, sensorValue, sensorUnit, measuredTime
      FROM ${aiven_kafka_topic.observations-weather-enriched.topic_name}
      PK rsid,sensorId
      EOF
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}