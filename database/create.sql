CREATE TABLE IF NOT EXISTS weather_stations (roadstationid int primary key, name varchar(128), latitude float, longitude float);
CREATE TABLE IF NOT EXISTS weather_sensors (sensorid int primary key, name varchar(128), unit varchar(8), accuracy smallint);

