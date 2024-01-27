package io.aiven.flink.tmsdemo;

import org.apache.flink.api.common.serialization.DeserializationSchema.InitializationContext;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.typeutils.TupleTypeInfo;
import org.apache.flink.connector.kafka.source.reader.deserializer.KafkaRecordDeserializationSchema;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.util.Collector;
import org.apache.kafka.clients.consumer.ConsumerRecord;

import java.io.IOException;
import java.nio.charset.StandardCharsets;


public class KafkaObservationSourceSchema implements KafkaRecordDeserializationSchema<Tuple2<String, Observation>> {

    private static final long serialVersionUID = 1L;

    private transient ObjectMapper objectMapper;

    /**
     * For performance reasons it's better to create on ObjectMapper in this open method rather than
     * creating a new ObjectMapper for every record.
     */
    @Override
    public void open(InitializationContext context) {
        objectMapper = new ObjectMapper();
    }

    /**
     * If our deserialize method needed access to the information in the Kafka headers of a
     * KafkaConsumerRecord, we would have implemented a KafkaRecordDeserializationSchema instead of
     * extending AbstractDeserializationSchema.

    @Override
    public Observation deserialize(byte[] message) throws IOException {
        return objectMapper.readValue(message, Observation.class);
    } */

    @Override
    public TypeInformation<Tuple2<String, Observation>> getProducedType() {
        return new TupleTypeInfo<>(TypeInformation.of(String.class), TypeInformation.of(Observation.class));
    }

    @Override
    public void deserialize(ConsumerRecord<byte[], byte[]> kafkaRecord, Collector<Tuple2<String, Observation>> out) throws IOException {

        out.collect(new Tuple2<>(new String(kafkaRecord.key(),
                    StandardCharsets.UTF_8), objectMapper.readValue(kafkaRecord.value(), Observation.class)));
    }


}