data "aiven_kafka_user" "kafka_admin" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name

  # default admin user that is automatically created for each Aiven service
  username = "avnadmin"
}

resource "aiven_kafka_user" "tms-ingest-user" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  username = "tms-ingest-user"
}

resource "aiven_kafka_user" "tms-processing-user" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  username = "tms-processing-user"
}

resource "aiven_kafka_acl" "tms-ingest-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "write"
  username = aiven_kafka_user.tms-ingest-user.username
  topic = aiven_kafka_topic.observations-weather-raw.topic_name
}

# read-write access for Kafka Streams topologies
resource "aiven_kafka_acl" "tms-processing-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "readwrite"
  username = aiven_kafka_user.tms-processing-user.username
  topic = "observations.*"
}

# read access to PostgeSQL CDC topics
resource "aiven_kafka_acl" "tms-processing-stations-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "read"
  username = aiven_kafka_user.tms-processing-user.username
  topic = "pg-stations.public.*"
}

# read access to PostgeSQL CDC topics
resource "aiven_kafka_acl" "tms-processing-sensors-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "read"
  username = aiven_kafka_user.tms-processing-user.username
  topic = "pg-sensors.public.*"
}

# adming access for intermediate Kafka Streams topics (changelog)
resource "aiven_kafka_acl" "tms-processing-admin-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "admin"
  username = aiven_kafka_user.tms-processing-user.username
  topic = "tms-streams-demo-*"
}

# adming access for intermediate Kafka Streams topics (changelog)
resource "aiven_kafka_acl" "tms-processing-admin-acl-2" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "admin"
  username = aiven_kafka_user.tms-processing-user.username
  topic = "tms-microservice-demo-*"
}

resource "aiven_kafka_schema_registry_acl" "tms-sr-acl" {
  project = var.avn_project_id
  service_name = aiven_kafka.tms-demo-kafka.service_name
  permission = "schema_registry_write"
  username = data.aiven_kafka_user.kafka_admin.username
  resource = "Subject:*"
}