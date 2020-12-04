from confluent_kafka import avro
from confluent_kafka import Consumer
from confluent_kafka.avro import AvroConsumer, CachedSchemaRegistryClient
from confluent_kafka.avro.serializer.message_serializer import MessageSerializer as AvroSerde

import requests

import os

influxdb_client = os.getenv("M3_INFLUXDB_URL").rstrip()
influxdb_cred = os.getenv("M3_INFLUXDB_CREDENTIALS").rstrip()
group_name = "tms-demo-m3-sink"
schema_registry = CachedSchemaRegistryClient(os.getenv("SCHEMA_REGISTRY"))
avro_serde = AvroSerde(schema_registry)
deserialize_avro = avro_serde.decode_message

def to_buffer(buffer: list, message):
    try:                    
        value = deserialize_avro(message=message.value(), is_key=False)
    except Exception as e:                    
        print(f"Failed deserialize avro payload: {message.value()}\n{e}")
    else:
        buffer.append("{measurement},roadStationId={road_station_id},name={name},municipality={municipality} sensorValue={sensor_value} {timestamp}"                    
            .format(measurement="observations",
                    road_station_id=value["roadStationId"],
                    name=value["name"],
                    municipality=bytes(value["municipality"], 'utf-8').decode('unicode-escape').replace(" ", "_"),
                    sensor_value=value["sensorValue"],
                    timestamp=value["measuredTime"] * 1000 * 1000))

def flush_buffer(buffer: list):
    print(f"Flushing {len(buffer)} records to M3")
    payload = str("\n".join(buffer))    
    response = requests.post(influxdb_client, data=payload, 
    auth=(influxdb_cred.split(":")[0],influxdb_cred.split(":")[1]), 
    headers={'Content-Type': 'application/x-www-form-urlencoded'})                                        
    if response.status_code != 204:        
        print(f"Failed to store to M3 {response.status_code}\n{response.text}")
        return False
    
    buffer.clear()
    return True

def consume_record(lines: list):    

    consumer_config = {"bootstrap.servers": os.getenv("BOOTSTRAP_SERVERS"),                        
                        "group.id": group_name,
                        "max.poll.interval.ms": 30000,
                        "session.timeout.ms": 20000,
                        "default.topic.config": {"auto.offset.reset": "latest"},
                        "security.protocol": "SSL",
                        "ssl.ca.location": "/etc/streams/tms-sink-cert/ca.pem",
                        "ssl.certificate.location": "/etc/streams/tms-sink-cert/service.cert",
                        "ssl.key.location": "/etc/streams/tms-sink-cert/service.key"
                       }

    consumer = Consumer(consumer_config)    
    consumer.subscribe(["observations.weather.municipality"])

    while True:
        try:
            message = consumer.poll(1)
        except Exception as e:
            print(f"Exception while trying to poll messages - {e}")
            exit(-1)
        else:
            if message:
                to_buffer(lines, message)
                                   
                if (len(lines) > 1000 and flush_buffer(lines) == True):
                    consumer.commit()
            
    consumer.close()


if __name__ == "__main__":
    lines = []
    consume_record(lines)
