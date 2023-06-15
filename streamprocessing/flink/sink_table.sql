create table observations_sink (
    roadStationId INT,
    sensorId INT,
    sensorName VARCHAR,
    sensorValueAvg DOUBLE,
    sensorValueMin DOUBLE,
    sensorValueMax DOUBLE,
    sensorValueCount BIGINT,
    sensorUnit VARCHAR,
    windowStart TIMESTAMP(2),
    windowEnd TIMESTAMP(2),
    PRIMARY KEY (roadStationId, sensorId, windowStart) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'properties.bootstrap.servers' = '',
    'topic' = '${sink_topic}',
    'value.format' = 'avro-confluent',
    'value.avro-confluent.url' = '${sr_uri}',
    'value.avro-confluent.basic-auth.credentials-source' = 'USER_INFO',
    'value.avro-confluent.basic-auth.user-info' = '${sr_user_info}',
    'key.format' = 'avro-confluent',
    'key.avro-confluent.url' = '${sr_uri}',
    'key.avro-confluent.basic-auth.credentials-source' = 'USER_INFO',
    'key.avro-confluent.basic-auth.user-info' = '${sr_user_info}'
)
