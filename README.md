# Data pipeline using Kafka and M3DB

Prerequisite
- Active Aiven account and project (https://aiven.io/)
- Aiven CLI (https://github.com/aiven/aiven-client)
- Terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)
- k8s cluster and kubectl command line tool
- jq command line tool (https://stedolan.github.io/jq/download/)
- kafkacat tool (https://github.com/edenhill/kafkacat)

## Infrastructure
```
cd infra
terraform apply
````

## Download secrets
````
./get-aiven-creds.sh <aiven-project-name>
````

## Create k8s resources
````
cd k8s
````

### Namespace
```
kubectl apply -f namespace.yaml
```


### Secrets
```
./init-secrets.sh
```

### Deployments
```
kubectl apply -f deploy-ingest.yaml
kubectl apply -f deploy-processing.yaml
kubectl apply -f deploy-sink.yaml
```

### Produce weather station metadata
```
cd producer
./import-stations.sh
```
