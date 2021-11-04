# Observability stack for managed Aiven services, Kubernetes and Kafka Streams with Prometheus, M3 and OpenSearch

This directory contains K8s manifests for deploying observability capabilities. There is also a git submodule for Highlander reverse proxy. Highlander is used for de-duplicating metrics from HA Prometheus setup.

# M3 user config

Use following avn command to create M3 write user and assign to group. This user is then used for Highlander

````
avn service user-create --project <aiven-project> --username <write user> --m3-group <group> <m3 service>
````

Now create another user to be used for Grafana Prometheus data source

````
avn service user-create --project <aiven-project> --username <read user> --m3-group <group> <m3 service>
````

# Highlander

Hihlander is a reverse proxy on Prometheus write path. It only allow single client to write to target (M3) so effectively deduplicates datapoints written by replicated Prometheus deployment (HA)


## Deploy
````
kubectl apply -f k8s/highlander.yaml
````

# Prometheus

We use Jsonnet and Jsonnet-bundler for creating Prometheus Kubernetes manifests.

Install gojsontoyaml
````
go install gojsontoyaml@latest
````

Build k8s manifests

````
cd prometheus
jb init
jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.9
./build.sh example-0.9.jsonnet
printf "  remoteWrite:\n   - url: \"http://highlander:9092/api/v1/prom/remote/write\"\n" >> manifests/prometheus-prometheus.yaml
kubectl apply -f manifests/setup
kubectl apply -f manifests
````

Deploy ServiceMonitor for the stream processing microservices
````
kubectl apply -f k8s/prometheus-servicemonitor.yaml
````
