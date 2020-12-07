package io.aiven.streams;

import java.util.HashMap;
import java.util.Map;

import org.apache.avro.generic.GenericRecord;
import org.apache.commons.text.StringEscapeUtils;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Produced;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import ch.hsr.geohash.GeoHash;
import fi.saily.tmsdemo.DigitrafficMessage;
import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;

@Component
@Profile("enrichment")
public class EnrichmentTopology {    

    private EnrichmentTopology() {
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
        

        // Sourced weather stations from PostreSQL table
        KTable<String, GenericRecord> stationTable = 
        streamsBuilder.table("tms-demo-pg.public.weather_stations", Consumed.with(Serdes.String(), genericSerde));        

        KStream<String, DigitrafficMessage> avroWeatherStream = 
            streamsBuilder.stream("observations.weather.processed", 
        Consumed.with(Serdes.String(), valueSerde).withTimestampExtractor(new ObservationTimestampExtractor()));

        avroWeatherStream
        .filter((k, v) -> !k.isBlank())
        .join(stationTable, (measurement, station) -> 
            DigitrafficMessage.newBuilder(measurement)
            .setMunicipality(StringEscapeUtils.unescapeJava(station.get("municipality").toString()))
            .setGeohash(calculateGeohash(station))
            .build()
        )        
        .to("observations.weather.municipality", Produced.with(Serdes.String(), valueSerde));
        
        return streamsBuilder.build();  
    }

    private static final String calculateGeohash(GenericRecord station) {        
        return GeoHash.geoHashStringWithCharacterPrecision(Double.parseDouble(station.get("latitude").toString()), 
        Double.parseDouble(station.get("longitude").toString()), 6);
    }
}
