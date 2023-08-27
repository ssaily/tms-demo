FROM eclipse-temurin:17-jre
# copy the packaged jar file into our docker image
COPY build/libs/streams-0.9.5-SNAPSHOT.jar /demo.jar
COPY jmx-config/kafka-client.yaml /kafka-client.yaml
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar /
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.26.0/opentelemetry-javaagent.jar /

# set the startup command to execute the jar
#CMD ["java", "-jar", "/demo.jar"]
ENTRYPOINT exec java $JAVA_OPTS $TRACING_OPTS -jar /demo.jar
