create table weather.observations_ob (
        roadStationId UInt16,
        sensorId UInt8,
        sensorName LowCardinality(String),
        sensorValue Float32 CODEC(Gorilla, ZSTD(1)),
        sensorUnit LowCardinality(String),
        geohash String,
        h3_10 UInt64 Codec(T64, ZSTD(1)),
        measuredTime DateTime64(3) CODEC(DoubleDelta, ZSTD(1))
    )
    ENGINE=ReplicatedReplacingMergeTree
    PARTITION BY (toYYYYMM(measuredTime))
    ORDER BY (roadStationId, sensorId, measuredTime);