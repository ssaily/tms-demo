package io.aiven.flink.tmsdemo;

import java.util.Properties;

import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchemaBuilder;

import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.formats.json.JsonDeserializationSchema;
import org.apache.flink.formats.json.JsonSerializationSchema;
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

    public <T> KafkaSource<T> createJsonKafkaSource(final String topic, final String kafkaGroup, final JsonDeserializationSchema<T> schema) {
        return KafkaSource.<T>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setTopics(topic)
            .setGroupId(kafkaGroup)
            .setProperties(kafkaProperties)
            .setValueOnlyDeserializer(schema)
            .build();

    }

    public <T> KafkaSink<T> createJsonKafkaSink(final String topic) {
        JsonSerializationSchema<T> jsonFormat = new JsonSerializationSchema<>();
        return KafkaSink.<T>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setRecordSerializer(new KafkaRecordSerializationSchemaBuilder<>()
                .setValueSerializationSchema(jsonFormat)
                .setTopic(topic)
                .build())
            .build();

    }

}
