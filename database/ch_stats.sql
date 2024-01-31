SELECT partition, formatReadableSize(sum(bytes))
FROM system.parts
WHERE table = 'observations_ob'
GROUP BY partition;

SELECT
    database,
    table,
    formatReadableSize(sum(data_compressed_bytes) AS size) AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes) AS usize) AS uncompressed,
    round(usize / size, 2) AS compr_rate,
    sum(rows) AS rows,
    count() AS part_count
FROM system.parts
WHERE (active = 1) AND (database = 'weather') AND (table LIKE 'observations%')
GROUP BY
    database,
    table
ORDER BY size DESC;

SELECT
    database,
    table,
    column,
    formatReadableSize(sum(column_data_compressed_bytes) AS size) AS compressed,
    formatReadableSize(sum(column_data_uncompressed_bytes) AS usize) AS uncompressed,
    round(usize / size, 2) AS compr_ratio,
    sum(rows) AS rows_cnt,
    round(usize / rows_cnt, 2) AS avg_row_size
FROM system.parts_columns
WHERE (active = 1) AND (database = 'weather') AND (table LIKE 'observations%')
GROUP BY
    database,
    table,
    column
ORDER BY size DESC;

# data distribution between storage tiers (defaul/remote)
SELECT
    database,
    table,
    disk_name,
    formatReadableSize(sum(data_compressed_bytes)) AS total_size,
    count(*) AS parts_count,
    formatReadableSize(min(data_compressed_bytes)) AS min_part_size,
    formatReadableSize(median(data_compressed_bytes)) AS median_part_size,
    formatReadableSize(max(data_compressed_bytes)) AS max_part_size
FROM system.parts
GROUP BY
    database,
    table,
    disk_name
ORDER BY
    database ASC,
    table ASC,
    disk_name ASC;
