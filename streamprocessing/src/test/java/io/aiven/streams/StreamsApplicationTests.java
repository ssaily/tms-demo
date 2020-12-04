package io.aiven.streams;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.Collections;
import java.util.Map;
import java.util.Properties;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TestOutputTopic;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.TopologyTestDriver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.kafka.support.serializer.JsonSerde;
import org.springframework.kafka.support.serializer.JsonSerializer;

import fi.saily.tmsdemo.DigitrafficMessage;
import io.confluent.kafka.schemaregistry.client.MockSchemaRegistryClient;
import io.confluent.kafka.schemaregistry.client.SchemaRegistryClient;
import io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException;
import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;

@ExtendWith(MockitoExtension.class)
class StreamsApplicationTests {
    private static Properties config;
    private static SpecificAvroSerde<DigitrafficMessage> serde;
    private static Serde<GenericRecord> genericSerde;
    private final SchemaRegistryClient schemaRegistryClient;

    public StreamsApplicationTests() {
        final Map<String, String> schemaRegistryConfig = Collections
                .singletonMap(AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG, "mocked");

        schemaRegistryClient = new MockSchemaRegistryClient();
        
        serde = new SpecificAvroSerde<>(schemaRegistryClient);
        serde.configure(schemaRegistryConfig, false);

        genericSerde = new GenericAvroSerde(schemaRegistryClient);
        serde.configure(schemaRegistryConfig, false);

        config = new Properties();
        config.setProperty(StreamsConfig.APPLICATION_ID_CONFIG, "tms-test-app");
        config.setProperty(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "foo:1234");
        config.setProperty(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
        config.setProperty(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, JsonSerde.class.getName());
        config.put(JsonSerializer.ADD_TYPE_INFO_HEADERS, true);
        config.put(JsonDeserializer.TRUSTED_PACKAGES, "*");
        config.setProperty(JsonDeserializer.VALUE_DEFAULT_TYPE, JsonNode.class.getName());

    }

    @BeforeEach
    public void setup() throws IOException, RestClientException {

    }

    
    @Test
    public void shouldCreateAvroFromJson() {
        
        Topology topology = StreamsTopology.kafkaStreamTopology(serde, genericSerde);
        TopologyTestDriver testDriver = new TopologyTestDriver(topology, config);

        TestInputTopic<String, JsonNode> inputTopic = testDriver.createInputTopic(
            "observations.weather.raw",
            new StringSerializer(),
            new JsonSerializer<>()); 
        
        ObjectMapper mapper = new ObjectMapper();
        JsonNode jsonObj = null;
        
        try {
            jsonObj = mapper.readTree("{\"id\": 132, \"roadStationId\": 12016, \"name\": \"KUITUVASTE_SUURI_1\", \"oldName\": " +
            "\"fiberresponsebig1\", \"shortName\": \"KVaS1 \", \"sensorValue\": 0.0, \"sensorUnit\": \"###\", " +
            "\"measuredTime\": \"2020-12-02T20:42:00Z\"}");
        } catch (Exception e) {
            
        }
            
        inputTopic.pipeInput("12016", jsonObj);

        TestOutputTopic<String, DigitrafficMessage> outputTopic = testDriver.createOutputTopic(
            "observations.weather.processed",
            new StringDeserializer(),
            serde.deserializer());

        assertThat(outputTopic.readKeyValue(), equalTo(new KeyValue<>("12016", 
            DigitrafficMessage.newBuilder()
                .setId(132)
                .setRoadStationId(12016)
                .setName("KUITUVASTE_SUURI_1")
                .setSensorValue(0.0f)
                .setSensorUnit("###")
                .setMeasuredTime(Instant.parse("2020-12-02T20:42:00Z").toEpochMilli()).build())));
        testDriver.close();
    }
    /*
    @Test
    public void shouldEnrichMunicipality() throws IOException, RestClientException  {

        Path resourceDirectory = Paths.get("src","test","resources");
        String absolutePath = resourceDirectory.toFile().getAbsolutePath() + "/station.avsc";         
        
        Schema schema = new Schema.Parser().parse(new File(absolutePath));            
        GenericRecord record = new GenericData.Record(schema);
        record.put("roadstationid", 12016);
        record.put("name", "somename");
        record.put("municipality", "Kärsämäki");
    
        schemaRegistryClient.register("tms-demo-pg.public.weather_stations", record.getSchema());

        Topology topology = StreamsTopology.kafkaStreamTopology(serde, genericSerde);
        TopologyTestDriver testDriver = new TopologyTestDriver(topology, config);

        TestInputTopic<String, DigitrafficMessage> inputTopic = testDriver.createInputTopic(
            "observations.weather.processed",
            new StringSerializer(),
            serde.serializer()); 
        
        TestInputTopic<String, GenericRecord> inputStationTopic = testDriver.createInputTopic(
            "tms-demo-pg.public.weather_stations",
            new StringSerializer(),
            genericSerde.serializer());         

        TestOutputTopic<String, DigitrafficMessage> outputTopic = testDriver.createOutputTopic(
            "observations.weather.municipality",
            new StringDeserializer(),
            serde.deserializer());

            
        inputTopic.pipeInput("12016", DigitrafficMessage.newBuilder()
            .setId(132)
            .setRoadStationId(12016)
            .setName("KUITUVASTE_SUURI_1")
            .setSensorValue(0.0f)
            .setSensorUnit("###")
            .setMeasuredTime(Instant.parse("2020-12-02T20:42:00Z").toEpochMilli()).build());
        
        inputStationTopic.pipeInput("12016", record);

        assertThat(outputTopic.readKeyValue(), equalTo(new KeyValue<>("12016", 
            DigitrafficMessage.newBuilder()
                .setId(132)
                .setRoadStationId(12016)
                .setName("KUITUVASTE_SUURI_1")
                .setSensorValue(0.0f)
                .setSensorUnit("###")
                .setMunicipality("Kärsämäki")
                .setMeasuredTime(Instant.parse("2020-12-02T20:42:00Z").toEpochMilli()).build())));
        testDriver.close();
    }    
    */
}
