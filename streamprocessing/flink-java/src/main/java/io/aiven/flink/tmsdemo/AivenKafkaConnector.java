package io.aiven.flink.tmsdemo;

import java.util.Properties;

import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;

import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.connector.kafka.source.reader.deserializer.KafkaRecordDeserializationSchema;
import org.apache.flink.table.api.TableDescriptor;
import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class AivenKafkaConnector {

    protected static final Logger logger = LogManager.getLogger(AivenKafkaConnector.class.getName());

    private final Properties kafkaProperties;
    private final String bootstrapServers;

    public AivenKafkaConnector(final KafkaSaslSslConfig kafkaSaslSslConfig) {
        this.bootstrapServers = kafkaSaslSslConfig.getBootstrapServers();
        this.kafkaProperties = new Properties();
        this.kafkaProperties.setProperty(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, kafkaSaslSslConfig.getSecurityProtocol());
        this.kafkaProperties.setProperty(SslConfigs.SSL_TRUSTSTORE_TYPE_CONFIG, "PEM");
        this.kafkaProperties.setProperty(SaslConfigs.SASL_MECHANISM,kafkaSaslSslConfig.getSaslSsl().getSaslMechanism());
        this.kafkaProperties.setProperty(SslConfigs.SSL_ENDPOINT_IDENTIFICATION_ALGORITHM_CONFIG, kafkaSaslSslConfig.getSaslSsl().getSslEndpointIdentificationAlgorithm());
        this.kafkaProperties.setProperty(SslConfigs.SSL_TRUSTSTORE_CERTIFICATES_CONFIG, kafkaSaslSslConfig.getSaslSsl().getSslCaCert());
        this.kafkaProperties.setProperty(SaslConfigs.SASL_JAAS_CONFIG,
                "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"" +
                kafkaSaslSslConfig.getSaslSsl().getSaslUsername() + "\" password=\"" +
                kafkaSaslSslConfig.getSaslSsl().getSaslPassword() + "\";");

        logger.info("Kafka properties:\n {}", this.kafkaProperties);


    }

    public AivenKafkaConnector(final KafkaPlainTextConfig plainTextConfig) {
        this.bootstrapServers = plainTextConfig.getBootstrapServers();
        this.kafkaProperties = new Properties();

    }

    public final <K, V> KafkaSource<Tuple2<K, V>> createJsonKafkaSource(final String topic, final String kafkaGroup, final KafkaRecordDeserializationSchema<Tuple2<K, V>> schema) {
        return KafkaSource.<Tuple2<K, V>>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setTopics(topic)
            .setGroupId(kafkaGroup)
            .setProperties(this.kafkaProperties)
            .setDeserializer(schema)
            .setStartingOffsets(OffsetsInitializer.earliest())
            .build();

    }

    public final <K, V> KafkaSink<Tuple2<K, V>> createJsonKafkaSink(KafkaRecordSerializationSchema<Tuple2<K, V>> schema) {
        return KafkaSink.<Tuple2<K, V>>builder()
            .setBootstrapServers(this.bootstrapServers)
            .setKafkaProducerConfig(this.kafkaProperties)
            .setRecordSerializer(schema)
            .build();

    }

    public final TableDescriptor createKafkaTableDescriptor() {
        return TableDescriptor.forConnector("kafka")
            .format("debezium-avro")
            .build();
    }

}
