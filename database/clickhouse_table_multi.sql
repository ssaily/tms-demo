create table weather.observations_ob_multi (
        roadStationId UInt16,
        measuredTime DateTime CODEC(DoubleDelta, ZSTD(1)),
        measurements Map(LowCardinality(String), Float32),
        geohash String
    )
    ENGINE=ReplicatedReplacingMergeTree
    PARTITION BY (toYYYYMM(measuredTime))
    ORDER BY (roadStationId, measuredTime);