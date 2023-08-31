#!/bin/sh
set -a
. .ch.env
curl ${CH_URL} -s --data-binary @clickhouse_table.sql
curl ${CH_URL} -s --data-binary @clickhouse_mv.sql
curl ${CH_URL} -s --data-binary @clickhouse_table_multi.sql
curl ${CH_URL} -s --data-binary @clickhouse_multi_mv.sql
set +a
