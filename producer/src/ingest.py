from paho.mqtt import client as mqtt_client
from confluent_kafka import SerializingProducer
from confluent_kafka.serialization import StringSerializer
import json
import os
import time
import binascii
from prometheus_kafka_producer.metrics_manager import ProducerMetricsManager
from prometheus_client import start_http_server

metric_manager = ProducerMetricsManager()

MQTT_HOST = os.getenv("MQTT_HOST")
MQTT_PORT = int(os.getenv("MQTT_PORT"))
MQTT_TOPICS = os.getenv("MQTT_TOPICS")
MSG_KEY = os.getenv("MSG_KEY")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC")

CLIENT_ID = os.getenv("CLIENT_PREFIX") + "-" + str(binascii.hexlify(os.urandom(8)))

def connect_kafka() -> SerializingProducer:
    producer_config = {
        'bootstrap.servers': os.getenv("BOOTSTRAP_SERVERS"),
        "statistics.interval.ms": 10000,
        'client.id': CLIENT_ID,
        'key.serializer': StringSerializer("utf8"),
        'value.serializer': StringSerializer("utf8"),
        'compression.type': 'gzip',
        'security.protocol': 'SSL',
        'ssl.ca.location': '/etc/streams/tms-ingest-cert/ca.pem',
        'ssl.certificate.location': '/etc/streams/tms-ingest-cert/service.cert',
        'ssl.key.location': '/etc/streams/tms-ingest-cert/service.key', 
        'stats_cb': metric_manager.send,      
    }
    producer = SerializingProducer(producer_config)
    return producer

producer = connect_kafka()

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
        global producer
        try:
            json_message = json.loads(msg.payload.decode())
            topic = msg.topic.split("/")
            roadstation_id = topic[1]
            sensor_id = topic[2]
            json_message["roadStationId"] = int(roadstation_id)
            json_message["sensorId"] = int(sensor_id)
                    
            producer.produce(topic=KAFKA_TOPIC, 
                key=roadstation_id,
                value=json.dumps(json_message))
        
        except ValueError:
            print("Failed to decode message as JSON: {}".format(msg.payload.decode()))
        except:
            print("Unknown error decoding topic: {} msg: {}".format(msg.topic.decode(), msg.payload.decode()))
      
    client.subscribe(MQTT_TOPICS)
    client.on_message = on_message


def run():
    producer = connect_kafka()
    client = connect_mqtt()
    client.loop_forever()
    producer.flush()


if __name__ == '__main__':
    start_http_server(9091)
    run()
