#!/bin/sh
kubectl create secret generic tms-service-cert \
--from-file=../tms-secrets/service.cert \
--from-file=../tms-secrets/service.key \
--from-file=../tms-secrets/ca.pem \
--from-file=../tms-secrets/client.keystore.p12 \
--from-file=../tms-secrets/client.truststore.jks \
-n tms-demo
kubectl create secret generic tms-service-endpoint \
--from-file=BOOTSTRAP_SERVERS=../tms-secrets/kafka_service_uri \
--from-file=SCHEMA_REGISTRY=../tms-secrets/schema_registry_uri \
--from-file=M3_INFLUXDB_URL=../tms-secrets/influxdb_uri \
--from-file=M3_INFLUXDB_CREDENTIALS=../tms-secrets/influxdb_credentials \
-n tms-demo
kubectl apply -f secrets.yaml
