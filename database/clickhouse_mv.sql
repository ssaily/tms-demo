CREATE MATERIALIZED VIEW weather.observations_ob_mv TO weather.observations_ob AS
SELECT
    roadStationId,
    sensorId,
    sensorName,
    sensorValue,
    sensorUnit,
    geohash,
    geoToH3(longitude, latitude, 10) as h3_10,
    measuredTime
FROM `service_tms-demo-kafka`.observations;
