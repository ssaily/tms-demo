package io.aiven.flink.tmsdemo;

import java.util.Properties;

import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;

import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.connector.kafka.source.reader.deserializer.KafkaRecordDeserializationSchema;
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

    public <K, V> KafkaSource<Tuple2<K, V>> createJsonKafkaSource(final String topic, final String kafkaGroup, final KafkaRecordDeserializationSchema<Tuple2<K, V>> schema) {
        return KafkaSource.<Tuple2<K, V>>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setTopics(topic)
            .setGroupId(kafkaGroup)
            .setProperties(kafkaProperties)
            .setDeserializer(schema)
            .setStartingOffsets(OffsetsInitializer.earliest())
            .build();

    }

    public <K, V> KafkaSink<Tuple2<K, V>> createJsonKafkaSink(KafkaRecordSerializationSchema<Tuple2<K, V>> schema) {
        return KafkaSink.<Tuple2<K, V>>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setRecordSerializer(schema)
            .build();

    }

}
