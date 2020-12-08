#!/bin/sh
[ ! -d "tms-secrets/ingest" ] && avn service user-kafka-java-creds --project $1 --username tms-ingest-user -p supersecret -d tms-secrets/ingest tms-demo-kafka
[ ! -d "tms-secrets/processing" ] && avn service user-kafka-java-creds --project $1 --username tms-processing-user -p supersecret -d tms-secrets/processing tms-demo-kafka
[ ! -d "tms-secrets/sink" ] && avn service user-kafka-java-creds --project $1 --username tms-sink-user -p supersecret -d tms-secrets/sink tms-demo-kafka
[ ! -d "tms-secrets/admin" ] && avn service user-kafka-java-creds --project $1 --username avnadmin -p supersecret -d tms-secrets/admin tms-demo-kafka
avn service get tms-demo-m3db --json -v|jq -r '"https://" + (.service_uri_params.host + ":" + .service_uri_params.port + "/api/v1/influxdb/write")' > tms-secrets/influxdb_uri
avn service get tms-demo-m3db --json -v|jq -r '(.service_uri_params.user + ":" + .service_uri_params.password)' > tms-secrets/influxdb_credentials
avn service get tms-demo-kafka --json -v|jq -r .connection_info.schema_registry_uri > tms-secrets/schema_registry_uri
avn service get tms-demo-kafka --json -v|jq -r .service_uri > tms-secrets/kafka_service_uri
avn service get tms-demo-pg --json -v|jq -r '("host=" + .service_uri_params.host + " port=" + .service_uri_params.port + " dbname=" + .service_uri_params.dbname + " user=" + .service_uri_params.user + " password=" + .service_uri_params.password)' > tms-secrets/pgpassfile
