$SPARK_HOME/bin/spark-shell \
--master local[2] \
--conf spark.executor.instances=1 \
--packages org.apache.spark:spark-avro_2.12:3.0.1,org.apache.hadoop:hadoop-cloud-storage:3.0.1,org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1,za.co.absa:abris_2.12:4.0.1 \
--repositories http://packages.confluent.io/maven/
