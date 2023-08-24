create table weather.observations_ob (roadStationId LowCardinality(String), sensorId UInt64, sensorName String, sensorValue Float, sensorUnit String, geohash String, measuredTime DateTime64(3) CODEC(Delta(4), ZSTD(1))) ENGINE=ReplicatedReplacingMergeTree ORDER BY (roadStationId, sensorId, measuredTime);
