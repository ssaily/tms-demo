jq -c '.[]' weather-stations-2.json|jq -r '"\(.id);\(.properties)"'|kafkacat -F kafkacat.conf -P -X topic.partitioner=murmur2_random -t stations.weather -K ";" -z gzip
