package fi.saily.tmsdemo

import org.apache.spark.sql.{DataFrame, Column, SparkSession}
import org.apache.spark.sql.functions.{col, to_timestamp, from_unixtime, avg, min, max, asc, count, window}
import org.apache.log4j.{LogManager, Level}
import org.apache.spark.sql.expressions.Window

object SparkExampleS3 {
    val log = LogManager.getLogger(SparkExample.getClass())    

    def main(args: Array[String]) {        
        log.info("Starting")
        val spark = SparkSession
        .builder
        .appName("SparkExample")
        .getOrCreate()       

        import spark.implicits._
    
        val df = spark.read.format("avro").load("s3a://<bucket>")
                    
        val byRange = df
            .withColumn("Date", to_timestamp($"measuredTime" / 1000))            
            .filter(col("Date") >= "2020-12-22 11:00:00Z")
            .filter(col("Date") < "2020-12-22 13:00:00Z")
            .groupBy(col("roadStationId"), window(col("Date"), "1 hour"))
            .agg(count("*").as("count"))      
            
        //show the data
        byRange.orderBy(col("roadStationId"), col("window.start"))
        .select(col("roadStationId"), col("window.start"), col("count"))
        .coalesce(1)
        .write.format("csv").save("out/results_s3.csv")
    }
}