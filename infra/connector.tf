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

# without Debezium change data envolope (ExtractNewRecordState)
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
    "topic.prefix": "tms",
    "slot.name": "station_repl_slot",
    "publication.autocreate.mode": "disabled",
    "publication.name": "station_publication",
    "snapshot.mode": "always",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",    
    "table.whitelist": "public.weather_stations,public.traffic_stations",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "transforms": "unwrap,createKey,extractInt",
    #"transforms": "unwrap",
    "transforms.unwrap.type":"io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones":"false",
    "transforms.createKey.type": "org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.createKey.fields": "roadstationid",      
    "transforms.extractInt.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractInt.field": "roadstationid",
    "include.schema.changes": "false",
    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": aiven_kafka_topic.dlq-sink.topic_name,
    #"errors.deadletterqueue.topic.replication.factor": 1,
    "errors.deadletterqueue.context.headers.enable": "true"
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
    "topic.prefix": "tms2",
    "slot.name": "station2_repl_slot",
    "publication.autocreate.mode": "disabled",
    "publication.name": "station_publication",
    "snapshot.mode": "always",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",    
    "table.whitelist": "public.weather_stations_2",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "transforms":"route",
    "transforms.route.regex": "tms2.public.weather_stations_2",
    "transforms.route.replacement": "weather_stations",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "include.schema.changes": "false"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

# without Debezium change data envolope (ExtractNewRecordState)
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
    "topic.prefix": "tms",
    "slot.name": "sensor_repl_slot",
    "publication.autocreate.mode": "disabled",
    "publication.name": "station_publication",
    "snapshot.mode": "always",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",    
    "table.whitelist": "public.weather_sensors,public.traffic_sensors",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "transforms": "unwrap,insertKey,extractKey",
    #"transforms": "unwrap",
    "transforms.unwrap.type":"io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones":"false",
    "transforms.insertKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.insertKey.fields":"sensorid",
    "transforms.extractKey.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field":"sensorid",
    "include.schema.changes": "false",
    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": aiven_kafka_topic.dlq-sink.topic_name,
    #"errors.deadletterqueue.topic.replication.factor": 1,
    "errors.deadletterqueue.context.headers.enable": "true"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

resource "aiven_kafka_connector" "kafka-pg-cdc-sensors-2" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "kafka-pg-cdc-sensors-2"

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
    "name": "kafka-pg-cdc-sensors-2",
    "topic.prefix": "tms2",
    "slot.name": "sensor2_repl_slot",
    "publication.autocreate.mode": "disabled",
    "publication.name": "station_publication",
    "snapshot.mode": "always",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_pg_user.pg_admin.username,
    "database.password": data.aiven_pg_user.pg_admin.password,
    "database.dbname": "defaultdb",    
    "table.whitelist": "public.weather_sensors",
    "plugin.name": "pgoutput",
    "database.sslmode": "require",
    "include.schema.changes": "false"
  }
  depends_on = [
    aiven_service_integration.tms-demo-connect-integr
  ]
}

resource "aiven_kafka_connector" "kafka-dragonfly-sink" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "kafka-dragonfly-sink"
  config = {
    "name": "kafka-dragonfly-sink",
    "_aiven.restart.on.failure": "true",
    "connector.class": "com.datamountaineer.streamreactor.connect.redis.sink.RedisSinkConnector",
    "key.converter" : "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "topics": aiven_kafka_topic.observations-weather-enriched.topic_name,
    "connect.redis.host": aiven_dragonfly.tms-demo-dragonfly.service_host,
    "connect.redis.port": aiven_dragonfly.tms-demo-dragonfly.service_port,
    "connect.redis.password": aiven_dragonfly.tms-demo-dragonfly.service_password,
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

resource "aiven_kafka_connector" "s3-parquet-sink" {
  count = "${var.aws_access_key_id != "" ? 1 : 0}"
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect.service_name
  connector_name = "s3-parquet-sink"
  config = {
    "_aiven.restart.on.failure": "true",
    "name": "s3-parquet-sink",
    "connector.class": "io.aiven.kafka.connect.s3.AivenKafkaConnectS3SinkConnector",
    "key.converter" : "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": local.schema_registry_uri,
    "value.converter.basic.auth.credentials.source": "URL",
    "value.converter.schemas.enable": "true",
    "topics": aiven_kafka_topic.observations-weather-multivariate.topic_name,
    "aws.access.key.id": var.aws_access_key_id,
    "aws.secret.access.key": var.aws_secret_access_key,
    "aws.s3.bucket.name": var.aws_s3_bucket_name,
    "aws.s3.region": var.aws_s3_region,
    "format.output.type": "parquet",
    "file.name.template": "measurements/{{topic}}-part{{partition}}-off{{start_offset}}.parquet"
    "errors.tolerance": "none",
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "offset.flush.interval.ms": "10000"
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