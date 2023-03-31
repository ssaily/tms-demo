create table observations_source (
    k_roadStationId VARCHAR,
    roadStationId INT,
    sensorId INT,
    sensorName VARCHAR,
    sensorValue DOUBLE,
    sensorUnit VARCHAR,
    measuredTime TIMESTAMP(3),
    municipality VARCHAR,
    WATERMARK FOR measuredTime AS measuredTime - INTERVAL '60' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = '',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'observations.weather.municipality',
    'key.format' = 'raw',
    'key.fields-prefix' = 'k_',
    'key.fields' = 'k_roadStationId',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'value.avro-confluent.url' = '${SCHEMA_REGISTRY_URL}',
    'value.avro-confluent.basic-auth.credentials-source' = 'USER_INFO',
    'value.avro-confluent.basic-auth.user-info' = '${SCHEMA_REGISTRY_CREDENTIALS}'
)