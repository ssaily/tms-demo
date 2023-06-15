INSERT INTO observations_sink
SELECT roadStationId, sensorId, sensorName,
AVG(sensorValue) as sensorValueAvg,
MIN(sensorValue) as sensorValueMin,
MAX(sensorValue) as sensorValueMax,
COUNT(*) as sensorValueCount,
sensorUnit, window_start as windowStart, max(measuredTime) as windowEnd
FROM TABLE( TUMBLE(TABLE observations_source,
    DESCRIPTOR(measuredTime), INTERVAL '1' HOUR))
GROUP BY window_start,
GROUPING SETS ((roadStationId, sensorId, sensorName, sensorUnit));
