FROM adoptopenjdk/openjdk14:x86_64-alpine-jre-14.0.2_12
# copy the packaged jar file into our docker image
COPY build/libs/streams-0.1.1-SNAPSHOT.jar /demo.jar

# set the startup command to execute the jar
CMD ["java", "-jar", "/demo.jar"]
