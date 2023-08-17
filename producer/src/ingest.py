import asyncio
from threading import Thread
from paho.mqtt import client as mqtt_client
import confluent_kafka
from confluent_kafka import KafkaException
from confluent_kafka.serialization import StringSerializer
import json
import os
import time
import binascii
from prometheus_kafka_producer.metrics_manager import ProducerMetricsManager
from prometheus_client import start_http_server
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
from opentelemetry.trace import Status, StatusCode, SpanKind
from opentelemetry.sdk.resources import SERVICE_NAME, SERVICE_INSTANCE_ID, Resource
from opentelemetry.semconv.trace import SpanAttributes
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.instrumentation.confluent_kafka import ConfluentKafkaInstrumentor
from opentelemetry.sdk.trace.export import BatchSpanProcessor

inst = ConfluentKafkaInstrumentor()

# Resource can be required for some backends, e.g. Jaeger
# If resource wouldn't be set - traces wouldn't appears in Jaeger
resource = Resource(attributes={
    "service.name": "tms-demo-ingest"
})

trace.set_tracer_provider(TracerProvider(resource=resource))

otlp_exporter = OTLPSpanExporter(endpoint="http://simple-aiven-collector-headless.tms-demo.svc:4317", insecure=True)

span_processor = BatchSpanProcessor(otlp_exporter)

tracer_provider = trace.get_tracer_provider()
tracer_provider.add_span_processor(span_processor)
tracer = trace.get_tracer("tms-demo-ingest")

class AIOProducer:
    def __init__(self, configs, loop=None):
        self._loop = loop or asyncio.get_event_loop()
        p = confluent_kafka.Producer(configs)
        self._producer = inst.instrument_producer(p, tracer_provider)
        self._cancelled = False
        self._poll_thread = Thread(target=self._poll_loop)
        self._poll_thread.start()
        print("New AIOProducer")

    def _poll_loop(self):
        while not self._cancelled:
            self._producer.poll(1)

    def close(self):
        self._cancelled = True
        self._poll_thread.join()

    def produce(self, topic, key, value):
        """
        An awaitable produce method.
        """
        result = self._loop.create_future()

        def ack(err, msg):
            if err:
                self._loop.call_soon_threadsafe(result.set_exception, KafkaException(err))
            else:
                self._loop.call_soon_threadsafe(result.set_result, msg)
        self._producer.produce(topic=topic, key=key, value=value, on_delivery=ack)
        return result

    def produce2(self, topic, key, value, on_delivery=None):
        """
        A produce method in which delivery notifications are made available
        via both the returned future and on_delivery callback (if specified).
        """
        result = self._loop.create_future()

        def ack(err, msg):
            if err:
                self._loop.call_soon_threadsafe(
                    result.set_exception, KafkaException(err))
            else:
                self._loop.call_soon_threadsafe(
                    result.set_result, msg)
            if on_delivery:
                self._loop.call_soon_threadsafe(
                    on_delivery, err, msg)
        self._producer.produce(topic=topic, key=key, value=value, on_delivery=ack)
        return result

metric_manager = ProducerMetricsManager()

MQTT_HOST = os.getenv("MQTT_HOST")
MQTT_PORT = int(os.getenv("MQTT_PORT"))
MQTT_TOPICS = os.getenv("MQTT_TOPICS")
MSG_KEY = os.getenv("MSG_KEY")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC")
MSG_MULTIPLIER = int(os.getenv("MSG_MULTIPLIER"))

CLIENT_ID = os.getenv("CLIENT_PREFIX") + "-" + str(binascii.hexlify(os.urandom(8)))

def connect_kafka() -> AIOProducer:
    producer_config = {
        'bootstrap.servers': os.getenv("BOOTSTRAP_SERVERS"),
        "statistics.interval.ms": 10000,
        'client.id': CLIENT_ID,
        'partitioner': 'murmur2_random',
        #'key.serializer': StringSerializer("utf8"),
        #'value.serializer': StringSerializer("utf8"),
        'compression.type': 'gzip',
        'linger.ms': 5000,
        'queue.buffering.max.messages': 500000,
        'security.protocol': 'SSL',
        'ssl.ca.location': '/etc/streams/tms-ingest-cert/ca.pem',
        'ssl.certificate.location': '/etc/streams/tms-ingest-cert/service.cert',
        'ssl.key.location': '/etc/streams/tms-ingest-cert/service.key',
        'stats_cb': metric_manager.send,
    }
    return AIOProducer(producer_config)


def connect_mqtt(kafka_producer: AIOProducer) -> mqtt_client:
    print("Connecting client {}".format(CLIENT_ID))
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected, return code {}\n".format(rc))
            subscribe(client)
        else:
            print("Failed to connect, return code {}\n".format(rc))

    def on_disconnect(client, userdata, rc):
        print("Disconnected, return code {}\n".format(rc))

    client = mqtt_client.Client(client_id = CLIENT_ID, transport = "websockets", userdata = kafka_producer)
    client.on_disconnect = on_disconnect
    client.on_connect = on_connect
    client.username_pw_set(username=os.getenv("MQTT_USER"), password=os.getenv("MQTT_PASSWORD"))
    client.tls_set()
    client.connect(MQTT_HOST, MQTT_PORT)
    return client

def subscribe(client: mqtt_client):
    @tracer.start_as_current_span("tms-demo-ingest_on_message", kind=SpanKind.SERVER, attributes={SpanAttributes.MESSAGING_PROTOCOL: "MQTT"})
    def on_message(client, userdata, msg):
        try:
            json_message = json.loads(msg.payload.decode())
            topic = msg.topic.split("/")
            roadstation_id = topic[1]
            sensor_id = topic[2]
            event_time = int(json_message["time"])
            json_message["sensorId"] = int(sensor_id)

            for x in range(MSG_MULTIPLIER):
                if x > 0:
                    time.sleep(0.0001)
                json_message["time"] = event_time
                userdata.produce(topic=KAFKA_TOPIC,
                    key=roadstation_id,
                    value=json.dumps(json_message))
                event_time += x

        except ValueError as err:
            print("Failed to decode message as JSON: {} {}".format(err,msg.payload.decode()))
        except KafkaException as err:
            print("KafkaException: {}".format(err))
        except Exception as err:
            print("Unknown error {} decoding topic: {} msg: {}".format(err, msg.topic, msg.payload.decode()))

    client.subscribe(MQTT_TOPICS)
    client.on_message = on_message


def run():
    aio_producer = connect_kafka()
    client = connect_mqtt(aio_producer)
    client.loop_forever()
    aio_producer.close()

if __name__ == '__main__':
    start_http_server(9091)
    run()
