#!/bin/sh
kubectl create secret generic tms-ingest-cert \
--from-file=../tms-secrets/ingest/service.cert \
--from-file=../tms-secrets/ingest/service.key \
--from-file=../tms-secrets/ingest/ca.pem \
--from-file=../tms-secrets/ingest/client.keystore.p12 \
--from-file=../tms-secrets/ingest/client.truststore.jks \
-n tms-demo
kubectl create secret generic tms-processing-cert \
--from-file=../tms-secrets/processing/service.cert \
--from-file=../tms-secrets/processing/service.key \
--from-file=../tms-secrets/processing/ca.pem \
--from-file=../tms-secrets/processing/client.keystore.p12 \
--from-file=../tms-secrets/processing/client.truststore.jks \
-n tms-demo
kubectl create secret generic tms-sink-cert \
--from-file=../tms-secrets/sink/service.cert \
--from-file=../tms-secrets/sink/service.key \
--from-file=../tms-secrets/sink/ca.pem \
--from-file=../tms-secrets/sink/client.keystore.p12 \
--from-file=../tms-secrets/sink/client.truststore.jks \
-n tms-demo
kubectl create secret generic tms-service-endpoint \
--from-file=BOOTSTRAP_SERVERS=../tms-secrets/kafka_service_uri \
--from-file=SCHEMA_REGISTRY=../tms-secrets/schema_registry_uri \
--from-file=M3_INFLUXDB_URL=../tms-secrets/influxdb_uri \
--from-file=M3_INFLUXDB_CREDENTIALS=../tms-secrets/influxdb_credentials \
-n tms-demo
kubectl apply -f secrets.yaml
