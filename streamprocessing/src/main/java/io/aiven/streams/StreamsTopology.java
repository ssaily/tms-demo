package io.aiven.streams;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import com.fasterxml.jackson.databind.JsonNode;

import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Produced;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;

import fi.saily.tmsdemo.DigitrafficMessage;
import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;

import org.apache.avro.generic.GenericRecord;
import org.apache.commons.text.StringEscapeUtils;

@Component
public class StreamsTopology {
    private static Logger logger = LoggerFactory.getLogger(StreamsTopology.class);        
    
    private StreamsTopology() {
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
        Serde<GenericRecord> genericSerde = new GenericAvroSerde();

        valueSerde.configure(serdeConfig, false);
        genericSerde.configure(serdeConfig, false);
        
        KStream<String, JsonNode> jsonWeatherStream = streamsBuilder.stream("observations.weather.raw");
        jsonWeatherStream        
        .map((k,v) -> convertToAvro(v))
        .filter((k, v) -> !k.isBlank())
        .to("observations.weather.processed", Produced.with(Serdes.String(), valueSerde));                
        
        // Sourced weather stations from PostreSQL table
        KTable<String, GenericRecord> stationTable = streamsBuilder.table("tms-demo-pg.public.weather_stations", Consumed.with(Serdes.String(), genericSerde));

        KStream<String, DigitrafficMessage> avroWeatherStream = 
            streamsBuilder.stream("observations.weather.processed", 
        Consumed.with(Serdes.String(), valueSerde));
        
        avroWeatherStream
        .filter((k, v) -> !k.isBlank())
        .join(stationTable, (measurement, station) -> 
            DigitrafficMessage.newBuilder(measurement)
            .setMunicipality(
                StringEscapeUtils.unescapeJava(station.get("municipality").toString()))
                .build())        
        .to("observations.weather.municipality", Produced.with(Serdes.String(), valueSerde));        
                           
        return streamsBuilder.build();
    }
    
    private static final KeyValue<String, DigitrafficMessage> convertToAvro(JsonNode v) {        
        Optional<JsonNode> stationId = Optional.ofNullable(v.get("roadStationId"));
        if (stationId.isPresent()) {            
            Optional<JsonNode> id = Optional.ofNullable(v.get("id"));            
            Optional<JsonNode> name = Optional.ofNullable(v.get("name"));
            Optional<JsonNode> value = Optional.ofNullable(v.get("sensorValue"));
            Optional<JsonNode> time = Optional.ofNullable(v.get("measuredTime"));
            Optional<JsonNode> unit = Optional.ofNullable(v.get("sensorUnit"));
        
            final DigitrafficMessage msg = DigitrafficMessage.newBuilder()
            .setId(id.get().asInt())
            .setName(name.get().asText())
            .setSensorValue(value.get().asDouble())
            .setRoadStationId(stationId.get().asInt())
            .setMeasuredTime(Instant.parse(time.get().asText()).toEpochMilli())
            .setSensorUnit(unit.get().asText())
            .build();
            return KeyValue.pair(stationId.get().asText(), msg);
        } else {
            return KeyValue.pair("", null);
        }

    }

}
