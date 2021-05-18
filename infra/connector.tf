data "aiven_service_component" "schema_registry" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  component = "schema_registry"
  route = "dynamic"

  depends_on = [
    aiven_kafka.tms-demo-kafka
  ]
}

data "aiven_service_component" "tms_pg" {
    project = var.avn_project_id
    service_name = aiven_service.tms-demo-pg.service_name
    component = "pg"
    route = "dynamic"

    depends_on = [
        aiven_service.tms-demo-pg
    ]
}

locals {
  schema_registry_uri = "https://${data.aiven_service_user.kafka_admin.username}:${data.aiven_service_user.kafka_admin.password}@${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}"
}

resource "aiven_kafka_connector" "kafka-pg-cdc-stations" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect1.service_name
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
    "slot.name": "weatherstations",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_service_user.pg_admin.username,
    "database.password": data.aiven_service_user.pg_admin.password,
    "database.dbname": "defaultdb",
    "database.server.name": "tms-demo-pg",
    "table.whitelist": "public.weather_stations",
    "plugin.name": "wal2json",
    "database.sslmode": "require",
    "transforms": "unwrap,insertKey,extractKey",
    "transforms.unwrap.type":"io.debezium.transforms.UnwrapFromEnvelope",
    "transforms.unwrap.drop.tombstones":"false",
    "transforms.insertKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.insertKey.fields":"roadstationid",
    "transforms.extractKey.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field":"roadstationid",
    "include.schema.changes": "false"
  }

  depends_on = [ 
    aiven_service_integration.tms-demo-connect-integr,
    aiven_kafka_connect.tms-demo-kafka-connect1,
    aiven_kafka_topic.stations-weather,
    aiven_service.tms-demo-pg
  ]
}

resource "aiven_kafka_connector" "kafka-pg-cdc-sensors" {
  project = var.avn_project_id
  service_name = aiven_kafka_connect.tms-demo-kafka-connect1.service_name
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
    "slot.name": "weathersensors",
    "database.hostname": data.aiven_service_component.tms_pg.host,
    "database.port": data.aiven_service_component.tms_pg.port,
    "database.user": data.aiven_service_user.pg_admin.username,
    "database.password": data.aiven_service_user.pg_admin.password,
    "database.dbname": "defaultdb",
    "database.server.name": "tms-demo-pg",
    "table.whitelist": "public.weather_sensors",
    "plugin.name": "wal2json",
    "database.sslmode": "require",
    "transforms": "unwrap,insertKey,extractKey",
    "transforms.unwrap.type":"io.debezium.transforms.UnwrapFromEnvelope",
    "transforms.unwrap.drop.tombstones":"false",
    "transforms.insertKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.insertKey.fields":"sensorid",
    "transforms.extractKey.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field":"sensorid",
    "include.schema.changes": "false"
  }

  depends_on = [ 
    aiven_service_integration.tms-demo-connect-integr,
    aiven_kafka_connect.tms-demo-kafka-connect1,
    aiven_kafka_topic.sensors-weather,
    aiven_service.tms-demo-pg
  ]
}