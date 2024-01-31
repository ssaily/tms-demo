/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.aiven.flink.tmsdemo;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;

import org.apache.commons.cli.*;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import static org.apache.flink.table.api.Expressions.*;

/**
 * Skeleton for a Flink DataStream Job.
 *
 * <p>For a tutorial how to write a Flink application, check the
 * tutorials and examples on the <a href="https://flink.apache.org">Flink Website</a>.
 *
 * <p>To package your application into a JAR file for execution, run
 * 'mvn clean package' on the command line.
 *
 * <p>If you change the name of the main class (with the public static void main(String[] args))
 * method, change the respective entry in the POM.xml file (simply search for 'mainClass').
 */
public class FlinkJob {

    protected static final Logger logger = LogManager.getLogger(FlinkJob.class.getName());

	private final AivenKafkaConnector aivenKafka;
    private final String consumerGroupId;

	public static void main(String[] args) throws IOException, ParseException {

        CommandLine cmd = parseArguments(args);
        final FlinkJob dataStreamJob;

		if (cmd.getOptionValue("config-file") != null) {

            dataStreamJob = new FlinkJob(cmd.getOptionValue("consumer-group"),Path.of(cmd.getOptionValue("config-file")));
        } else if (cmd.getOptionValue("integration-id") != null) {

            dataStreamJob = new FlinkJob(cmd.getOptionValue("integration-id"), cmd.getOptionValue("consumer-group"));

        } else {
            throw new IllegalArgumentException("Wrong count of arguments");
        }
        dataStreamJob.executeDataStreamAPI();
        //dataStreamJob.executeTableAPI();
	}

	public FlinkJob(final String integrationId, final String consumerGroupId) throws IOException
    {
        this.consumerGroupId = consumerGroupId;
        this.aivenKafka = AivenKafkaConnectorFactory.INSTANCE.createAivenKafkaConnector(integrationId);

    }

	public FlinkJob(final String consumerGroupId, final Path configPath) throws IOException {
        this.consumerGroupId = consumerGroupId;
        this.aivenKafka = AivenKafkaConnectorFactory.INSTANCE.createAivenKafkaConnector(new ConfigFiles(configPath));

    }

	public void executeDataStreamAPI() throws IOException {

        KafkaObservationSourceSchema sourceSchema = new KafkaObservationSourceSchema();
        KafkaObservationSinkSchema sinkSchema = new KafkaObservationSinkSchema("observations.weather.flink-jar-out");


        final KafkaSource<Tuple2<String, Observation>> kafkaSource =
                aivenKafka.createJsonKafkaSource("observations.weather.raw", this.consumerGroupId, sourceSchema);

        final KafkaSink<Tuple2<String, Observation>> kafkaSink =
                aivenKafka.createJsonKafkaSink(sinkSchema);

        try (StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment()) {
            env.enableCheckpointing(10000); // milliseconds
            DataStream<Tuple2<String, Observation>> stream =
                env.fromSource(kafkaSource,
                        WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofMinutes(1)), "Raw observations");
            stream.sinkTo(kafkaSink);
            env.execute("DataStreamJob");
        } catch(Exception e) {
            throw new IOException(e);
        }

    }

    public void executeTableAPI() throws IOException {

        final EnvironmentSettings settings = EnvironmentSettings
            .newInstance()
            .inStreamingMode()
            .build();

        final TableEnvironment tEnv = TableEnvironment.create(settings);
        Schema.Builder schemaBuilder = Schema.newBuilder();

        final TableDescriptor sourceDescriptor =
            aivenKafka
                .initTableBuilder()
                .option("scan.startup.mode", "earliest-offset")
                .option("properties.group.id", "tabletest")
                .schema(schemaBuilder.column("sensorId", DataTypes.INT().notNull())
                    .column("name", DataTypes.STRING())
                    .column("unit", DataTypes.STRING())
                    .column("accuracy", DataTypes.SMALLINT())
                    .primaryKey("sensorId")
                    .build())
                .option("topic", "pg-sensors-3.public.weather_sensors")
                .format("debezium-avro-confluent")
                .build();

        tEnv.createTable("sensors", sourceDescriptor);
        Table sensors = tEnv.from("sensors");
        sensors.select($("sensorId"), $("name"), $("unit")).execute().print();

    }

    private static final CommandLine parseArguments(String[] args) throws ParseException {
        Options options = new Options();

        Option integrationId = new Option("i", "integration-id", true, "Aiven Integration ID");
        integrationId.setRequired(false);
        options.addOption(integrationId);

        Option consumerGroupName = new Option("g", "consumer-group", true, "Kafka Consumer Group name");
        consumerGroupName.setRequired(true);
        options.addOption(consumerGroupName);

        Option configFile = new Option("c", "config-file", true, "Load properties from file and execute local job");
        configFile.setRequired(false);
        options.addOption(configFile);

        CommandLineParser parser = new DefaultParser();

        return parser.parse(options, args);

    }


}
