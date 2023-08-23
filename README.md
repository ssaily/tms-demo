# Data pipeline with Kafka, Kafka Streams, Flink and M3DB

Prerequisites
- Active Aiven account and project (https://aiven.io/)
- Aiven CLI (https://github.com/aiven/aiven-client)
- Terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)
- k8s cluster and kubectl command line tool
- Helm 3 (https://helm.sh/docs/intro/install/)
- jq command line tool (https://stedolan.github.io/jq/download/)
- kcat tool (https://github.com/edenhill/kcat)
- Jaeger K8s operator for tracing (https://jaegertracing.github.io/helm-charts/)
- Keda K8s operator for autoscaling (https://keda.sh/docs/2.10/deploy/#helm)


## Infrastructure
```
cd <project-root>/infra
terraform apply
````

## Download secrets
````
./get-demo-secrets.sh <aiven-project-name>
````

## Prepare Postgres

### Import weather station metadata
```
cd <project-root>/database
./import-stations.sh
```

## Create k8s resources

### Jaeger Tracing
Example deployments are utilising OpenTelemetry tracing. Jaeger is now fully compatible with OTLP tracing protocol so we only need Jaeger Operator.
Follow the instructions on Jaeger Operator Helm Chart repo https://github.com/jaegertracing/helm-charts/tree/main/charts/jaeger-operator



### KEDA Autoscaling
https://keda.sh/

https://keda.sh/docs/2.10/deploy/
```
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
```

List of Helm releases should now look something like this
```
❯ helm list -A
NAME               	NAMESPACE    	REVISION	UPDATED                              	STATUS  	CHART                      	APP VERSION
cert-manager       	cert-manager 	1       	2023-04-13 10:52:16.765519 +0300 EEST	deployed	cert-manager-v1.11.1       	v1.11.1
jaeger-operator    	observability	1       	2023-08-15 15:26:01.075019 +0300 EEST	deployed	jaeger-operator-2.46.2     	1.46.0
keda               	keda         	1       	2023-04-03 11:55:40.19998 +0300 EEST 	deployed	keda-2.10.1                	2.10.0
```

Your Kubernetes cluster is now ready for deploying the example applications.

```
cd <project-root>/k8s
kubectl create -f namespace.yaml
kubectl apply -k .
```

### Deploy observability (Optional)
Follow instructions [here](observability/README.md)
