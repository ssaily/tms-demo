create table weather.observations_ob (roadStationId LowCardinality(String), sensorId UInt64, sensorName String, sensorValue Float, sensorUnit String, geohash String, measuredTime DateTime CODEC(Delta(4), ZSTD(1))) ENGINE=ReplicatedMergeTree ORDER BY (roadStationId, sensorId, measuredTime);
CREATE MATERIALIZED VIEW weather.observations_ob_mv TO weather.observations_ob AS
SELECT
    _key AS roadStationId,
    sensorId,
    sensorName,
    sensorValue,
    sensorUnit,
    geohash,
    measuredTime
FROM `service_tms-demo-kafka`.observations;
