OPENSEARCH_USER=$(cut -f1 -d : ../../tms-secrets/opensearch_credentials) \
OPENSEARCH_PASSWORD=$(cut -f2 -d : ../../tms-secrets/opensearch_credentials) \
envsubst '$OPENSEARCH_USER,$OPENSEARCH_PASSWORD' < fluentbit-configmap.template > fluentbit-configmap.yaml
