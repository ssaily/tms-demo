create table weather.observations_ob (stationId LowCardinality(String), sensorId UInt64, value Float, time DateTime CODEC(Delta(4), ZSTD(1))) ENGINE=ReplicatedMergeTree ORDER BY (stationId, sensorId, time);
CREATE MATERIALIZED VIEW weather.observations_ob_mv TO weather.observations_ob AS
SELECT
    _key AS stationId,
    sensorId,
    value,
    time
FROM `service_tms-demo-kafka`.observations;
