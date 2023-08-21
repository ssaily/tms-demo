INSERT INTO stats_sink
SELECT roadStationId,
COUNT(*) as messageCount
FROM observations_source
GROUP BY roadStationId;
