package io.aiven.streams;

import java.time.Instant;
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
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;

import fi.saily.tmsdemo.DigitrafficMessage;

@Component
public class StreamsTopology {
    private static Logger logger = LoggerFactory.getLogger(StreamsTopology.class);        
    
    private StreamsTopology() {
        /*
         * Private Constructor will prevent the instantiation of this class directly
         */
    }

    @Bean    
    public static Topology kafkaStreamTopology(Serde<DigitrafficMessage> valueSerde) {
            
        final StreamsBuilder streamsBuilder = new StreamsBuilder();
                
        
        KStream<String, JsonNode> jsonWeatherStream = streamsBuilder.stream("observations.weather.raw");
        jsonWeatherStream        
        .map((k,v) -> convertToAvro(v))
        .filter((k, v) -> !k.isBlank())
        .to("observations.weather.processed", Produced.with(Serdes.String(), valueSerde));                
        
        KTable<String, JsonNode> stationTable = streamsBuilder.table("stations.weather");

        KStream<String, DigitrafficMessage> avroWeatherStream = 
            streamsBuilder.stream("observations.weather.processed", 
        Consumed.with(Serdes.String(), valueSerde));
        
        avroWeatherStream
        .filter((k, v) -> !k.isBlank())
        .join(stationTable, (measurement, station) -> 
            DigitrafficMessage.newBuilder(measurement)
            .setMunicipality(station.get("municipality").asText()).build())        
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
            .setId(id.get().asLong())
            .setName(name.get().asText())
            .setSensorValue(value.get().asDouble())
            .setRoadStationId(stationId.get().asLong())
            .setMeasuredTime(Instant.parse(time.get().asText()).toEpochMilli())
            .setSensorUnit(unit.get().asText())
            .build();
            return KeyValue.pair(stationId.get().asText(), msg);
        } else {
            return KeyValue.pair("", null);
        }

    }

}
