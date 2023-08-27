package io.aiven.streams;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import com.fasterxml.jackson.databind.JsonNode;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.GlobalKTable;
import org.apache.kafka.streams.kstream.Produced;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Profile;
import org.springframework.kafka.support.serializer.JsonSerde;
import org.springframework.stereotype.Component;

import ch.hsr.geohash.GeoHash;
import fi.saily.tmsdemo.DigitrafficMessage;
import fi.saily.tmsdemo.WeatherStation;
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
        Serde<DigitrafficMessage> digitrafficSerde = new SpecificAvroSerde<>();
        Serde<GenericRecord> genericSerde = new GenericAvroSerde();
        digitrafficSerde.configure(serdeConfig, false);
        genericSerde.configure(serdeConfig, false);


        // Sourced weather stations from PostreSQL table
        KTable<String, WeatherStation> stationTable =
        streamsBuilder.table("pg-stations.public.weather_stations", Consumed.with(Serdes.String(), genericSerde))
        .mapValues((key, value) -> WeatherStation.newBuilder()
            .setRoadStationId((Integer)value.get("roadstationid"))
            .setLatitude((Double)value.get("latitude"))
            .setLongitude((Double)value.get("longitude"))
            .setGeohash(calculateGeohash(value))
            .setName("")
            .build()
            );

        // Sourced weeather sensors from Postgres table
        // We are using GlobalKTable here because the sensor table has different primary key (sensorId)

        GlobalKTable<String, GenericRecord> sensorTable =
        streamsBuilder.globalTable("pg-sensors.public.weather_sensors", Consumed.with(Serdes.String(), genericSerde));

        KStream<String, JsonNode> jsonWeatherStream = streamsBuilder.stream("observations.weather.raw",
            Consumed.with(Serdes.String(), new JsonSerde<>(JsonNode.class)));

        jsonWeatherStream
        .filter((k, v) -> !k.isBlank() && v.get("time") != null)
        .mapValues(EnrichmentTopology::convertToAvro)
        .join(stationTable,
            (measurement, station) -> // ValueJoiner
                DigitrafficMessage.newBuilder(measurement)
                .setLatitude(station.getLatitude())
                .setLongitude(station.getLongitude())
                .setGeohash(station.getGeohash())
                .build()
        )
        .join(sensorTable,
            (key, value) -> String.valueOf(value.getSensorId()), // KeyValueMapper
            (measurement, sensor) -> // ValueJoiner
                DigitrafficMessage.newBuilder(measurement)
                .setSensorUnit(sensor.get("unit").toString())
                .setSensorName(sensor.get("name").toString())
                .build()
        )
        .to("observations.weather.enriched", Produced.with(Serdes.String(), digitrafficSerde));

        return streamsBuilder.build();
    }

    private static final String calculateGeohash(GenericRecord station) {
        return GeoHash.geoHashStringWithCharacterPrecision(Double.parseDouble(station.get("latitude").toString()),
        Double.parseDouble(station.get("longitude").toString()), 6);
    }

    private static final DigitrafficMessage convertToAvro(String k, JsonNode v) {
        Optional<JsonNode> sensorId = Optional.ofNullable(v.get("sensorId"));
        Optional<JsonNode> value = Optional.ofNullable(v.get("value"));
        Optional<JsonNode> time = Optional.ofNullable(v.get("time"));

        if (sensorId.isPresent() && value.isPresent() && time.isPresent()) {
            return DigitrafficMessage.newBuilder()
            .setSensorId(sensorId.get().asInt())
            .setSensorValue(value.get().asDouble())
            .setRoadStationId(Integer.parseInt(k))
            .setMeasuredTime(Long.parseLong(time.get().asText()) * 1000)
            .build();
        } else {
            return null;
        }
    }
}
