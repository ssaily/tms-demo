
package io.aiven.flink.tmsdemo;

import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.core.JsonProcessingException;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.SerializationFeature;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.json.JsonMapper;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.kafka.clients.producer.ProducerRecord;

public class KafkaSinkSchema implements KafkaRecordSerializationSchema<Observation> {

    private static final long serialVersionUID = 1L;

    private String topic;
    private static final ObjectMapper objectMapper =
            JsonMapper.builder()
                    .build()
                    .registerModule(new JavaTimeModule())
                    .configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);

    public KafkaSinkSchema(String topic) {
        this.topic = topic;
    }

    @Override
    public ProducerRecord<byte[], byte[]> serialize(
            Observation msg, KafkaSinkContext context, Long timestamp) {
        try {
            return new ProducerRecord<>(
                topic,
                null, // choosing not to specify the partition
                null,
                objectMapper.writeValueAsBytes(msg));
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException(
                    "Could not serialize record: " + msg, e);
        }

    }


}