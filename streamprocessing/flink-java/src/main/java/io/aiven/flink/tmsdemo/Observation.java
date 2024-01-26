package io.aiven.flink.tmsdemo;

import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Observation {
    public Integer sensorId;
    public Long time;
    public Double value;

    public Observation() {}
    public Observation(final Integer sensorId, final Long time, final Double value) {
        this.sensorId = sensorId; this.time = time; this.value = value;
    }

}
