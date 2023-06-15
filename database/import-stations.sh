psql "$(< pgpassfile)" -f create.sql

curl -X GET "https://tie.digitraffic.fi/api/weather/v1/stations" -H "accept: application/geo+json" -H "Accept-Encoding: gzip, deflate"|jq -r '.features|map([(.properties.id|tostring), .properties.name, (.geometry.coordinates[1]|tostring), (.geometry.coordinates[0]|tostring)]|join(","))|join("\n")' > weather_stations.csv
psql "$(< pgpassfile)" -c "\copy weather_stations (roadstationid, name, latitude, longitude) from 'weather_stations.csv' CSV DELIMITER ',';"

curl -X GET "https://tie.digitraffic.fi/api/weather/v1/sensors" -H "accept: application/json" -H "Accept-Encoding: gzip, deflate"|gzip -dc|jq -r '.sensors|map([(.id|tostring), .name, .unit, (.accuracy|tostring)]|join(","))|join("\n")' > sensors.csv
psql "$(< pgpassfile)" -c "\copy weather_sensors (sensorid, name, unit, accuracy) from 'sensors.csv' CSV DELIMITER ',';"
