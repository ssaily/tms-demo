package fi.saily.tmsdemo

import org.apache.spark.sql.{DataFrame, Column, SparkSession}
import za.co.absa.abris.avro.parsing.utils.AvroSchemaUtils
import za.co.absa.abris.avro.registry.{LatestVersion, NumVersion, SchemaSubject}
import za.co.absa.abris.config.AbrisConfig
import za.co.absa.abris.config.FromAvroConfig
import org.apache.spark.sql.functions.{col, to_timestamp, from_unixtime, avg, min, max, asc, count, window}
import org.apache.log4j.{LogManager, Level}
import org.apache.spark.sql.expressions.Window

object SparkExample {
    

    def main(args: Array[String]) {     
        val log = LogManager.getLogger(SparkExample.getClass())
    
        val registryConfig = Map(
            AbrisConfig.SCHEMA_REGISTRY_URL -> "https://tms-demo-kafka-sa-demo.aivencloud.com:24952",
            "basic.auth.credentials.source" -> "USER_INFO",
            "basic.auth.user.info" -> ""
            )

        val abrisConfig = AbrisConfig
        .fromConfluentAvro
        .downloadReaderSchemaByLatestVersion
        .andTopicNameStrategy("observations.weather.municipality", isKey=false)
        .usingSchemaRegistry(registryConfig) // use the map instead of just url

        import za.co.absa.abris.avro.functions.from_avro    
        def readAvro(dataFrame: DataFrame, fromAvroConfig: FromAvroConfig): DataFrame = {
        dataFrame.select(from_avro(col("value"), fromAvroConfig) as 'data).select("data.*")
        }
        
        log.info("Starting")
        val spark = SparkSession
        .builder
        .appName("SparkExample")
        .getOrCreate()       

        import spark.implicits._
        val w = Window.orderBy(col("measuredTime")).rangeBetween(-3600000, Window.currentRow)

        val df = spark
            .read
            .format("kafka")
            .option("kafka.bootstrap.servers", "tms-demo-kafka-sa-demo.aivencloud.com:24949")
            .option("kafka.security.protocol","SSL")
            .option("kafka.ssl.protocol","TLS")
            .option("kafka.ssl.key.password","supersecret")
            .option("kafka.ssl.keystore.location","client.keystore.p12")
            .option("kafka.ssl.keystore.password","supersecret")
            .option("kafka.ssl.keystore.type","PKCS12")
            .option("kafka.ssl.truststore.location","client.truststore.jks")
            .option("kafka.ssl.truststore.password","supersecret")
            .option("kafka.ssl.truststore.type","JKS")
            .option("subscribe", "observations.weather.municipality")
            .option("includeHeaders", "true")
            .load()
                    
        val deserialized = readAvro(df, abrisConfig)
        log.info(deserialized.schema.toString())       

        val byRange = deserialized
            .withColumn("Date", to_timestamp($"measuredTime" / 1000))
            .filter(col("Date") >= "2020-12-22 11:00:00Z")
            .filter(col("Date") < "2020-12-22 13:00:00Z")
            .groupBy(col("roadStationId"), window(col("Date"), "1 hour"))
            .agg(count("*").as("count"))      
            
        //show the data
        byRange.orderBy(col("roadStationId"), col("window.start"))
        .select(col("roadStationId"), col("window.start"), col("count"))
        .coalesce(1)
        .write.format("csv").save("out/results_kafka.csv")
    }
}