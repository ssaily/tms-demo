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
    
        val df = spark.read.format("avro").load("s3a://tmsdemo/topics/observations.weather.municipality/processdate=20201218/")
                    
        val byRange = df
            .filter(col("id") === 1)
            .filter(col("roadStationId") === 7031)
            .withColumn("Date", to_timestamp($"measuredTime" / 1000))
            .groupBy(col("roadStationId"), window(col("Date"), "1 hour"))
            .agg(avg("sensorValue").as("avgTemp"), count("*").as("count"))      
            
        //show the data
        byRange.orderBy(col("roadStationId"), col("window.start")).show(truncate=false);
        
    }
}