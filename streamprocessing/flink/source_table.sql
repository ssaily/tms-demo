create table observations_source (
    k_roadStationId VARCHAR,
    roadStationId INT,
    sensorId INT,
    sensorName VARCHAR,
    sensorValue DOUBLE,
    sensorUnit VARCHAR,
    measuredTime TIMESTAMP(3),
    WATERMARK FOR measuredTime AS measuredTime - INTERVAL '60' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = '',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = '${src_topic}',
    'key.format' = 'raw',
    'key.fields-prefix' = 'k_',
    'key.fields' = 'k_roadStationId',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'value.avro-confluent.url' = '${sr_uri}',
    'value.avro-confluent.basic-auth.credentials-source' = 'USER_INFO',
    'value.avro-confluent.basic-auth.user-info' = '${sr_user_info}'
)
