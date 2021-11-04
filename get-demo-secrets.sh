#!/bin/sh
# Download Kafka service user certificates
[ ! -d "k8s/secrets/aiven/ingest" ] && avn service user-kafka-java-creds --project $1 --username tms-ingest-user -p supersecret -d k8s/secrets/aiven/ingest tms-demo-kafka
[ ! -d "k8s/secrets/aiven/processing" ] && avn service user-kafka-java-creds --project $1 --username tms-processing-user -p supersecret -d k8s/secrets/aiven/processing tms-demo-kafka
[ ! -d "k8s/secrets/aiven/sink" ] && avn service user-kafka-java-creds --project $1 --username tms-sink-user -p supersecret -d k8s/secrets/aiven/sink tms-demo-kafka
[ ! -d "k8s/secrets/aiven/admin" ] && avn service user-kafka-java-creds --project $1 --username avnadmin -p supersecret -d k8s/secrets/aiven/admin tms-demo-kafka

# Generate pgpassfile for bootstrapping PostgreSQL tables
avn service get tms-demo-pg --json -v|jq -r '("host=" + .service_uri_params.host + " port=" + .service_uri_params.port + " dbname=" + .service_uri_params.dbname + " user=" + .service_uri_params.user + " password=" + .service_uri_params.password)' > database/pgpassfile

# Define environment variables
SCHEMA_REGISTRY_HOST=$(avn service get tms-demo-kafka --project $1 --json -v|jq -r '.components[] | select(.component == "schema_registry") |"\(.host):\(.port)"')
M3_PROM_URI=$(avn service get tms-demo-obs-m3db --project $1 --json -v|jq -r '.components[] | select(.component == "m3coordinator_prom_remote_write") |"https://\(.host):\(.port)\(.path)"')
M3_PROM_USER=$(avn service user-get --username avnadmin --project $1 --format '{username}' tms-demo-obs-m3db)
M3_PROM_PWD=$(avn service user-get --username avnadmin --project $1 --format '{password}' tms-demo-obs-m3db)
M3_INFLUXDB_URI=$(avn service get tms-demo-iot-m3db --project $1 --json -v|jq -r '"https://" + (.service_uri_params.host + ":" + .service_uri_params.port + "/api/v1/influxdb/write")')
M3_CREDENTIALS=$(avn service user-get --username avnadmin --project $1 --format '{username}:{password}' tms-demo-iot-m3db)
SCHEMA_REGISTRY_URI=$(avn service get tms-demo-kafka --project $1 --json -v|jq -r .connection_info.schema_registry_uri)
KAFKA_SERVICE_URI=$(avn service get tms-demo-kafka --project $1 --json -v|jq -r .service_uri)


echo $SCHEMA_REGISTRY_URI > k8s/secrets/aiven/schema_registry_uri
echo $M3_INFLUXDB_URI > k8s/secrets/aiven/m3_influxdb_uri
echo $M3_CREDENTIALS > k8s/secrets/aiven/m3_credentials
echo $M3_PROM_USER > k8s/secrets/aiven/m3_prom_user
echo $M3_PROM_PWD > k8s/secrets/aiven/m3_prom_pwd
echo $M3_PROM_URI > k8s/secrets/aiven/m3_prom_uri
echo $KAFKA_SERVICE_URI > k8s/secrets/aiven/kafka_service_uri

# Generate truststore for Schema Registry CA
openssl s_client -connect $SCHEMA_REGISTRY_HOST -showcerts < /dev/null 2>/dev/null | awk '/BEGIN CERT/{s=1}; s{t=t "\n" $0}; /END CERT/ {last=t; t=""; s=0}; END{print last}' > k8s/secrets/aiven/sr-ca.cert
keytool -import -file k8s/secrets/aiven/sr-ca.cert -alias CA -keystore k8s/secrets/aiven/schema_registry.truststore.jks -storepass supersecret -noprompt

