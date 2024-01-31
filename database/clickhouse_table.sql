create table weather.observations_ob (
        roadStationId UInt16,
        sensorId UInt8,
        sensorName LowCardinality(String),
        `sensorValue.string` Nullable(String),
        `sensorValue.double` Nullable(Float32) CODEC(Gorilla, ZSTD(1)),
        `sensorValue.boolean` Nullable(Bool),
        `sensorValue.int` Nullable(UInt16),
        sensorUnit LowCardinality(String),
        geohash String,
        h3_10 UInt64 Codec(T64, ZSTD(1)),
        measuredTime DateTime64(3) CODEC(DoubleDelta, ZSTD(1))
    )
    ENGINE=ReplicatedReplacingMergeTree
    PARTITION BY (toYYYYMM(measuredTime))
    ORDER BY (roadStationId, sensorId, measuredTime);