# Terraform plan for Aiven resources

This plan will create a bunch of services within your Aiven project
- Kafka
- Kafka Connect Cluster
- PostgreSQL CDC source connectors for Kafka Connect
- BigQuery Sink Connector
- PostgreSQL database
- Flink Job for processing observations
- Topics, Users and ACLs for Kafka
- Clickhouse for storing weather observations
- M3 Time Series database for Prometheus monitoring

You should copy the ```secrets.tfvars.template``` file to ```secrets.tfvars``` and fill in your Aiven project name, token and cloud region. After that you can run

```
terraform apply -var-file=secrets.tfvars
```
