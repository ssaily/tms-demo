package io.aiven.streams;

import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.utils.Bytes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.*;
import org.apache.kafka.streams.kstream.Suppressed.BufferConfig;
import org.apache.kafka.streams.state.SessionStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import fi.saily.tmsdemo.CountAndSum;
import fi.saily.tmsdemo.DigitrafficAggregate;
import fi.saily.tmsdemo.DigitrafficMessage;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;

@Component
@Profile("multivariate")
public class CreateMultivariate {
    private static Logger logger = LoggerFactory.getLogger(CalculationsTopology.class);        
    
    private CreateMultivariate() {
        /*
         * Private Constructor will prevent the instantiation of this class directly
         */
    }

    @Bean    
    public static Topology kafkaStreamTopology(@Value("${spring.application.schema-registry}") String schemaRegistryUrl) {
            
        final StreamsBuilder streamsBuilder = new StreamsBuilder();
        
        // schema registry
        Map<String, String> serdeConfig = new HashMap<>();
        serdeConfig.put("schema.registry.url", schemaRegistryUrl);
        serdeConfig.put("basic.auth.credentials.source", "URL");
        Serde<DigitrafficMessage> valueSerde = new SpecificAvroSerde<>();
        Serde<DigitrafficAggregate> resultSerde = new SpecificAvroSerde<>();        
        
        valueSerde.configure(serdeConfig, false);
        resultSerde.configure(serdeConfig, false);

        Grouped<String, DigitrafficMessage> groupedMessage = Grouped.with(Serdes.String(), valueSerde);
        
        streamsBuilder.stream("observations.weather.municipality", 
            Consumed.with(Serdes.String(), valueSerde).withTimestampExtractor(new ObservationTimestampExtractor()))        
        .filter((k, v) -> v.getName() != null)        
        .groupByKey(groupedMessage) 
        .windowedBy(SessionWindows.with(Duration.ofMinutes(1)).grace(Duration.ofMinutes(2)))                
        .aggregate(
            () -> 0L, /* initializer */
            (aggKey, newValue, aggValue) -> aggValue = aggValue + 1, /* adder */
            (aggKey, leftAggValue, rightAggValue) -> leftAggValue + rightAggValue, /* session merger */
                Materialized.<String, Long, SessionStore<Bytes, byte[]>>as("sessionized-aggregated-stream-store") /* state store name */
            .withValueSerde(Serdes.Long())) /* serde for aggregate value */
        .toStream()
        .foreach((key, value) -> System.out.println(key + " => " + value));
 
        
        
        return streamsBuilder.build();
    }
    
    
    
}
