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

aio_producer = None

class AIOProducer:
    def __init__(self, configs, loop=None):
        self._loop = loop or asyncio.get_event_loop()
        self._producer = confluent_kafka.SerializingProducer(configs)
        self._cancelled = False
        self._poll_thread = Thread(target=self._poll_loop)
        self._poll_thread.start()

    def _poll_loop(self):
        while not self._cancelled:
            self._producer.poll(0.1)

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
        self._producer.produce(topic, key, value, on_delivery=ack)
        return result

    def produce2(self, topic, value, on_delivery):
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
        self._producer.produce(topic, value, on_delivery=ack)
        return result

metric_manager = ProducerMetricsManager()

MQTT_HOST = os.getenv("MQTT_HOST")
MQTT_PORT = int(os.getenv("MQTT_PORT"))
MQTT_TOPICS = os.getenv("MQTT_TOPICS")
MSG_KEY = os.getenv("MSG_KEY")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC")

CLIENT_ID = os.getenv("CLIENT_PREFIX") + "-" + str(binascii.hexlify(os.urandom(8)))

def connect_kafka() -> AIOProducer:
    producer_config = {
        'bootstrap.servers': os.getenv("BOOTSTRAP_SERVERS"),
        "statistics.interval.ms": 10000,
        'client.id': CLIENT_ID,
        'key.serializer': StringSerializer("utf8"),
        'value.serializer': StringSerializer("utf8"),
        'compression.type': 'gzip',
        'linger.ms': 5000,
        'security.protocol': 'SSL',
        'ssl.ca.location': '/etc/streams/tms-ingest-cert/ca.pem',
        'ssl.certificate.location': '/etc/streams/tms-ingest-cert/service.cert',
        'ssl.key.location': '/etc/streams/tms-ingest-cert/service.key',
        'stats_cb': metric_manager.send,
    }
    return AIOProducer(producer_config)


def connect_mqtt() -> mqtt_client:
    print("Connecting client {}".format(CLIENT_ID))
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected, return code {}\n".format(rc))
            subscribe(client)
        else:
            print("Failed to connect, return code {}\n".format(rc))

    def on_disconnect(client, userdata, rc):
        print("Disconnected, return code {}\n".format(rc))

    client = mqtt_client.Client(client_id = CLIENT_ID, transport="websockets")
    client.on_disconnect = on_disconnect
    client.on_connect = on_connect
    client.username_pw_set(username=os.getenv("MQTT_USER"), password=os.getenv("MQTT_PASSWORD"))
    client.tls_set()
    client.connect(MQTT_HOST, MQTT_PORT)
    return client

def subscribe(client: mqtt_client):
    def on_message(client, userdata, msg):
        global aio_producer
        try:
            json_message = json.loads(msg.payload.decode())
            topic = msg.topic.split("/")
            roadstation_id = topic[1]
            sensor_id = topic[2]
            json_message["sensorId"] = int(sensor_id)

            aio_producer.produce(topic=KAFKA_TOPIC,
                key=roadstation_id,
                value=json.dumps(json_message))

        except ValueError as err:
            print("Failed to decode message as JSON: {} {}".format(err,msg.payload.decode()))
        except KafkaException as err:
            print("KafkaException: {}".format(err))
        except Exception as err:
            print("Unknown error {} decoding topic: {} msg: {}".format(err, msg.topic, msg.payload.decode()))

    client.subscribe(MQTT_TOPICS)
    client.on_message = on_message


def run():
    global aio_producer
    aio_producer = connect_kafka()
    client = connect_mqtt()
    client.loop_forever()
    aio_producer.close()

if __name__ == '__main__':
    start_http_server(9091)
    run()
