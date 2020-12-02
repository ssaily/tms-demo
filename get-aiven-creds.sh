#!/bin/sh
[ ! -d "tms-secrets" ] && avn service user-kafka-java-creds --project $1 --username $2 -p supersecret -d tms-secrets tms-demo-kafka
avn service get tms-demo-m3db --json -v|jq -r '(.connection_info.influxdb_uri + "/write")' > tms-secrets/influxdb_uri
avn service get tms-demo-kafka --json -v|jq -r .connection_info.schema_registry_uri > tms-secrets/schema_registry_uri
avn service get tms-demo-kafka --json -v|jq -r .service_uri > tms-secrets/kafka_service_uri
