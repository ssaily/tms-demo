from paho.mqtt import client as mqtt_client
from kafka import KafkaProducer
import json
import os
import time

broker = 'tie.digitraffic.fi'
port = 61619
topic = "weather/#"

client_id = "tms-demo-ingest-" + str(time.time())

def connect_kafka() -> KafkaProducer:
    producer = KafkaProducer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS"),
        key_serializer=str.encode,
        value_serializer=str.encode,
        compression_type='gzip',
        security_protocol="SSL",
        ssl_cafile="/etc/streams/tms-ingest-cert/ca.pem",
        ssl_certfile="/etc/streams/tms-ingest-cert/service.cert",
        ssl_keyfile="/etc/streams/tms-ingest-cert/service.key",        
    )
    return producer

producer = connect_kafka()

def connect_mqtt() -> mqtt_client:
    print("Connecting client {}".format(client_id))
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected, return code {}\n".format(rc))
            subscribe(client)
        else:
            print("Failed to connect, return code {}\n".format(rc))

    def on_disconnect(client, userdata, rc):
        print("Disconnected, return code {}\n".format(rc))

    client = mqtt_client.Client(client_id = client_id, transport="websockets")
    client.on_disconnect = on_disconnect
    client.on_connect = on_connect
    client.username_pw_set(username=os.getenv("MQTT_USER"), password=os.getenv("MQTT_PASSWORD"))
    client.tls_set()
    client.connect(broker, port)
    return client

def subscribe(client: mqtt_client):
    def on_message(client, userdata, msg):
        try:
            json_message = json.loads(msg.payload.decode())
            roadstation_id = json_message.get("roadStationId")
            if roadstation_id:
                producer.send(topic="observations.weather.raw", key=str(json_message["roadStationId"]), 
                value=json.dumps(json_message))
            else:
                print("roadStationId not found: {}".format(msg.payload.decode()))
        except ValueError:
            print("Failed to decode message as JSON: {}".format(msg.payload.decode()))
  
    client.subscribe(topic)
    client.on_message = on_message


def run():
    client = connect_mqtt()            
    client.loop_forever()
    producer.flush()


if __name__ == '__main__':
    run()
