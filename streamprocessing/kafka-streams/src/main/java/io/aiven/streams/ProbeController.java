package io.aiven.streams;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import org.apache.kafka.streams.KafkaStreams;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Controller
public class ProbeController {
    private static Logger logger = LoggerFactory.getLogger(ProbeController.class);
    private final KafkaStreams kafkaStreams;

    ProbeController(KafkaStreams kafkaStreams) {
        this.kafkaStreams = kafkaStreams;
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        KafkaStreams.State appState = kafkaStreams.state();
        ResponseEntity<String> response = null;
        if (appState.equals(KafkaStreams.State.RUNNING)) {
            response = ResponseEntity.ok().build();
        } else {
            response = ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
            logger.info("GET health: " + appState.name());
        }

        return response;
    }
}
