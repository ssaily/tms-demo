log4f_properties="src/main/resources/log4j.properties"
log4j_setting="-Dlog4j.configuration=file:${log4f_properties}"
$SPARK_HOME/bin/spark-submit \
--master local[8] \
--conf spark.executor.instances=1 \
--driver-java-options="${log4j_setting}" \
--conf "spark.executor.extraJavaOptions=${log4j_setting}" \
--files src/main/resources/log4j.properties \
--name SparkExample \
--class fi.saily.tmsdemo.$1 \
--packages org.apache.spark:spark-avro_2.12:3.0.1,org.apache.hadoop:hadoop-cloud-storage:3.0.1,org.apache.spark:spark-sql-kafka-0-10_2.12:3.0.1,za.co.absa:abris_2.12:4.0.1,com.typesafe.scala-logging:scala-logging_2.12:3.9.2 \
--repositories http://packages.confluent.io/maven/ \
target/scala-2.12/tms-demo-spark_2.12-1.0.jar
