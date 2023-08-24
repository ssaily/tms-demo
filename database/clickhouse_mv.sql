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
