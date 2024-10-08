# Observability stack for managed Aiven services, Kubernetes and Kafka Streams with Prometheus, Thanos and OpenSearch

This directory contains K8s manifests for deploying observability capabilities. There is also a git submodule for Highlander reverse proxy. Highlander is used for de-duplicating metrics from HA Prometheus setup.

# Prometheus

We use Jsonnet and Jsonnet-bundler for creating Prometheus Kubernetes manifests.

Install gojsontoyaml
````
go install gojsontoyaml@latest
````

Now we can build the k8s manifests for Prometheus

````
cd prometheus
jb init
jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.9
./build.sh example-0.9.jsonnet
````

Next we will create the Prometheus Operator CRDs and Aiven for Thanos secrets

````
kubectl create -f manifests/setup
./create-thanos-secret.sh
````

Highlander is a reverse proxy on Prometheus write path. It only allow single client to write to target (Thanos) so effectively deduplicates datapoints written by replicated Prometheus deployment (HA)

Now that we have Thanos secrets in place it's time to deploy Highlander Proxy

````
kubectl create -f ../k8s/highlander.yaml
````

All is now in place for deploying the actual Prometheus instances

````
kubectl create -f manifests

````

With Prometheus running we can deploy ServiceMonitor for all our Kafka clients
````
kubectl create -f ../k8s/prometheus-servicemonitor.yaml
````
