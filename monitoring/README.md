# Monitoring Kubernetes and Kafka Streams with Prometheus

This directory contains git submodules for kube-prometheus and Highlander reverse proxy.

# M3 user config

Use following avn command to create M3 write user and assign to group. This user is then used for Highlander

avn service user-create --project <aiven-project> --username <write user> --m3-group <group> <m3 service>

Now create another user to be used for Grafana Prometheus data source

avn service user-create --project <aiven-project> --username <read user> --m3-group <group> <m3 service>

# Prometheus

Follow the instructions to setup Prometheus k8s operator
[kube-prometheus/README.md](kube-prometheus/README.md)

Modify [example.jsonnet](kube-prometheus/example.jsonnet) to include tms-demo namespace for service discovery
 [instructions](kube-prometheus/README.md#adding-additional-namespaces-to-monitor)

(Optional) Build Docker image for Highlander reverse proxy. At the moment you will have to use the forked version for authentication against Aiven M3

Deploy ServiceMonitor and Higlander using manifests at [k8s directory](k8s/)
