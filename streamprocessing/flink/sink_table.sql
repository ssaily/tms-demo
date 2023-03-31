create table observations_sink (
    roadStationId INT,
    sensorId INT,
    sensorName VARCHAR,
    sensorValueAvg DOUBLE,
    sensorValueMin DOUBLE,
    sensorValueMax DOUBLE,
    sensorValueCount BIGINT,
    sensorUnit VARCHAR,
    municipality VARCHAR,
    windowStart TIMESTAMP(2),
    windowEnd TIMESTAMP(2),
    PRIMARY KEY (roadStationId, sensorId, windowStart) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'properties.bootstrap.servers' = '',
    'topic' = 'observations.weather.flink-avg-avro',
    'value.format' = 'avro-confluent',
    'value.avro-confluent.url' = '${SCHEMA_REGISTRY_URL}',
    'value.avro-confluent.basic-auth.credentials-source' = 'USER_INFO',
    'value.avro-confluent.basic-auth.user-info' = '${SCHEMA_REGISTRY_CREDENTIALS}',
    'key.format' = 'avro-confluent',
    'key.avro-confluent.url' = '${SCHEMA_REGISTRY_URL}',
    'key.avro-confluent.basic-auth.credentials-source' = 'USER_INFO',
    'key.avro-confluent.basic-auth.user-info' = '${SCHEMA_REGISTRY_CREDENTIALS}'
)