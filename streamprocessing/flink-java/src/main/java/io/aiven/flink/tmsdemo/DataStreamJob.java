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

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

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
public class DataStreamJob {

    protected static final Logger logger = LogManager.getLogger(DataStreamJob.class.getName());

	private final String integrationId;
    private final String consumerGroupId;

	public static void main(String[] args) throws IOException {

		if (args.length != 2) {
            throw new IllegalArgumentException("Wrong count of arguments");
        }
        final String integrationId = args[0];
        final String consumerGroupId = args[1];

        final DataStreamJob dataStreamJob = new DataStreamJob(integrationId, consumerGroupId);
        dataStreamJob.execute();
	}

	public DataStreamJob(final String integrationId, final String consumerGroupId)
    {
        this(integrationId, consumerGroupId, null);
    }

	public DataStreamJob(final String integrationId, final String consumerGroupId, final Path configPath) {
        this.integrationId = integrationId;
        this.consumerGroupId = consumerGroupId;
    }

	public void execute() throws IOException {

        //final KafkaObservationSchema sourceSchema = new KafkaObservationSchema();
        //final KafkaSinkSchema sinkSkchema = new KafkaSinkSchema("observations.weather.flink_jar");

        final AivenKafkaConnector kafka = AivenKafkaConnectorFactory.INSTANCE.createAivenKafkaConnector(this.integrationId);
        final KafkaSource<Observation> kafkaSource =
            kafka.createKafkaSourceForTopic("observations.weather.raw", this.consumerGroupId);

        final KafkaSink<Observation> kafkaSink = kafka.createKafkaSink();
        try (StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment()) {
            DataStream<Observation> stream = env.fromSource(kafkaSource, WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofMinutes(1)), "Raw observations");
            stream.sinkTo(kafkaSink);
            env.execute("DataStreamJob");
        } catch(Exception e) {
            throw new IOException(e);
        }

    }
}
