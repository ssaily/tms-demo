CREATE MATERIALIZED VIEW weather.observations_ob_multi_mv TO weather.observations_ob_multi AS
SELECT
    roadStationId,
    measuredTime,
    measurements,
    geohash
FROM `service_tms-demo-kafka`.observations_multivariate;
