package io.aiven.flink.tmsdemo;

import java.nio.charset.StandardCharsets;

import org.apache.flink.api.common.serialization.SerializationSchema.InitializationContext;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class KafkaObservationSinkSchema implements KafkaRecordSerializationSchema<Tuple2<String, Observation>> {
    private transient ObjectMapper objectMapper;
    private final String topic;

    protected static final Logger logger = LogManager.getLogger(KafkaObservationSinkSchema.class.getName());

    private KafkaObservationSinkSchema() {
        this.topic = "";
    }

    public KafkaObservationSinkSchema(final String topic) {
        this.topic = topic;
    }

    @Override
    public void open(InitializationContext context, KafkaSinkContext sinkContext) throws Exception {
        this.objectMapper = new ObjectMapper();
    }


    @Override
    public ProducerRecord<byte[], byte[]> serialize(Tuple2<String, Observation> element, KafkaSinkContext context,
            Long timestamp) {

        try {
            return new ProducerRecord<>(this.topic, element.f0.getBytes(StandardCharsets.UTF_8),
            objectMapper.writeValueAsBytes(element.f1));

        } catch (Exception e) {
            logger.error("Unable to serialize JSON {} {}", element, e);
        }
        return new ProducerRecord<>(topic, null, null);
    }

}
