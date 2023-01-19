# Data pipeline using Kafka and M3DB

Prerequisite
- Active Aiven account and project (https://aiven.io/)
- Aiven CLI (https://github.com/aiven/aiven-client)
- Terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)
- k8s cluster and kubectl command line tool
- jq command line tool (https://stedolan.github.io/jq/download/)
- kcat tool (https://github.com/edenhill/kcat)

## Infrastructure
```
cd infra
terraform apply
````

## Download secrets
````
./get-demo-secrets.sh <aiven-project-name>
````

## Prepare Postgres

### Import weather station metadata
```
cd database
./import-stations.sh
```

### Create publication for Debezium CDC
```
avn service cli tms-demo-pg

=> CREATE EXTENSION aiven_extras CASCADE;
=> SELECT *
FROM aiven_extras.pg_create_publication_for_all_tables(
    'station_publication',
    'INSERT,UPDATE,DELETE'
    );
```

## Create k8s resources
````
cd k8s
````

### Namespace
```
kubectl create -f namespace.yaml
```

### Secrets
```
./create-k8s-secrets.sh
```

### Deploy observability (Optional)
Follow instructions [here](observability/README.md)

### Deployments
```
kubectl create -f deploy-ingest.yaml
kubectl create -f deploy-processing.yaml
kubectl create -f deploy-sink.yaml
kubectl create -f ksqldb.yaml
```

