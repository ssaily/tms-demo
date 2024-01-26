package io.aiven.flink.tmsdemo;

import java.util.Properties;

import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchemaBuilder;

import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.reader.deserializer.KafkaRecordDeserializationSchema;
import org.apache.flink.formats.json.JsonDeserializationSchema;
import org.apache.flink.formats.json.JsonSerializationSchema;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.node.ObjectNode;
import org.apache.flink.streaming.util.serialization.JSONKeyValueDeserializationSchema;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;

public class AivenKafkaConnector {
    private final Properties kafkaProperties;
    private final String bootstrapServers;

    public AivenKafkaConnector(final KafkaSaslSslConfig kafkaSaslSslConfig) {
        this.bootstrapServers = kafkaSaslSslConfig.getBootstrapServers();
        kafkaProperties = new Properties();
        kafkaProperties.setProperty(SaslConfigs.SASL_MECHANISM,kafkaSaslSslConfig.getSaslSsl().getSaslMechanism());
        kafkaProperties.setProperty(SslConfigs.SSL_ENDPOINT_IDENTIFICATION_ALGORITHM_CONFIG, kafkaSaslSslConfig.getSaslSsl().getSslEndpointIdentificationAlgorithm());
        kafkaProperties.setProperty(SslConfigs.SSL_TRUSTSTORE_CERTIFICATES_CONFIG, kafkaSaslSslConfig.getSaslSsl().getSslCaCert());
        kafkaProperties.setProperty(SaslConfigs.SASL_JAAS_CONFIG,
                "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"" +
                kafkaSaslSslConfig.getSaslSsl().getSaslUsername() + "\" password=\"" +
                kafkaSaslSslConfig.getSaslSsl().getSaslPassword() + "\";");

    }

    public AivenKafkaConnector(final KafkaPlainTextConfig plainTextConfig) {
        this.bootstrapServers = plainTextConfig.getBootstrapServers();
        kafkaProperties = new Properties();

    }

    public KafkaSource<Observation> createKafkaSourceForTopic(String topic, String kafkaGroup) {

        JsonDeserializationSchema<Observation> jsonFormat = new JsonDeserializationSchema<>(Observation.class);
        return KafkaSource.<Observation>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setTopics(topic)
            .setGroupId(kafkaGroup)
            .setProperties(kafkaProperties)
            .setValueOnlyDeserializer(jsonFormat)
            .build();

    }

    public KafkaSink<Observation> createKafkaSink() {
        JsonSerializationSchema<Observation> jsonFormat = new JsonSerializationSchema<>();
        return KafkaSink.<Observation>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setRecordSerializer(new KafkaRecordSerializationSchemaBuilder<>()
                .setValueSerializationSchema(jsonFormat)
                .setTopic("observations.weather.flink_jar")
                .build())
            .build();

    }

}
