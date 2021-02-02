name := "tms-demo-spark"

version := "1.0"

scalaVersion := "2.12.10"

resolvers += "Confluent" at "https://packages.confluent.io/maven/"

libraryDependencies += "org.apache.spark" %% "spark-sql" % "3.0.1"

libraryDependencies += "org.apache.spark" %% "spark-avro" % "3.0.1"

libraryDependencies += "org.apache.hadoop" % "hadoop-cloud-storage" % "3.0.1"

libraryDependencies += "org.apache.spark" %% "spark-sql-kafka-0-10" % "3.0.1"

libraryDependencies += "za.co.absa" %% "abris" % "4.0.1"

