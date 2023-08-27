create table weather.observations_ob (
        roadStationId UInt16,
        sensorId UInt8,
        sensorName LowCardinality(String),
        sensorValue Float,
        sensorUnit LowCardinality(String),
        geohash String,
        h3_10 UInt64,
        measuredTime DateTime64(3) CODEC(Delta(4), ZSTD(1))
    )
    ENGINE=ReplicatedReplacingMergeTree
    ORDER BY (roadStationId, sensorId, measuredTime);
