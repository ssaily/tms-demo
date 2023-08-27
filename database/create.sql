CREATE EXTENSION aiven_extras CASCADE;
SELECT * FROM aiven_extras.pg_create_publication_for_all_tables('station_publication','INSERT,UPDATE,DELETE');
CREATE TABLE IF NOT EXISTS weather_stations (roadstationid int primary key, name varchar(128), latitude float, longitude float);
CREATE TABLE IF NOT EXISTS weather_sensors (sensorid int primary key, name varchar(128), unit varchar(8), accuracy smallint);
CREATE TABLE IF NOT EXISTS traffic_stations (roadstationid int primary key, name varchar(128), latitude float, longitude float);
CREATE TABLE IF NOT EXISTS traffic_sensors (sensorid int primary key, name varchar(128), unit varchar(8));

